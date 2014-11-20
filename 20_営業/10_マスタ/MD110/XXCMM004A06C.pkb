CREATE OR REPLACE PACKAGE BODY XXCMM004A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A06C(body)
 * Description      : �����ꗗ�쐬
 * MD.050           : �����ꗗ�쐬 MD050_CMM_004_A06
 * Version          : Draft2C
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_init              ��������
 *  get_cmp_cost           �R���|�[�l���g�����擾
 *  get_item_mst           �i�ڏ��擾
 *  output_csv             CSV�t�@�C���o�̓v���V�[�W��
 *  submain                �����̎��s��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/11    1.0   N.Nishimura      main�V�K�쐬
 *  2009/01/16    1.1   R.Takigawa       CSV�`���f�[�^�o�̓G���[���폜
 *                                       �i�ڋ��ʌŒ�l��`
 *  2009/04/08    1.2   H.Yoshikawa      ��QNo.T1_0184 �Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER  := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE    := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER  := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE    := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER  := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER  := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER  := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER  := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE    := SYSDATE;                    --PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)  := '.';
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
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCMM004A06C';    -- �p�b�P�[�W��
  cv_app_name_xxcmm     CONSTANT VARCHAR2(5)   := 'XXCMM';           -- �A�v���P�[�V�����Z�k��
  -- �G���[���b�Z�[�W
  cv_msg_xxcmm_00470    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00470'; --�Ώۃf�[�^����
  cv_msg_xxcmm_00471    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00471'; --CSV�`���f�[�^�o�̓G���[
  cv_msg_xxcmm_00472    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00472'; --CSV�w�b�_
  -- ���b�N�A�b�v
  cv_lookup_cost_cmpt   CONSTANT VARCHAR2(20)  := 'XXCMM1_COST_CMPT';        -- �R���|�[�l���g�������
  cv_lookup_csv_head    CONSTANT VARCHAR2(30)  := 'XXCMM1_004A06_ITEMLIST';  -- ���ڃ^�C�g��
  -- �g�[�N��
  cv_tkn_year           CONSTANT VARCHAR2(10)  := 'YEAR';
  cv_tkn_cost_type      CONSTANT VARCHAR2(10)  := 'COST_TYPE';
  -- �萔
  cv_inp_calendar_code  CONSTANT VARCHAR2(30)  := '�W�������Ώ۔N�x�F';   -- �W�������Ώ۔N�x
  cv_inp_cost_type      CONSTANT VARCHAR2(30)  := '�c�ƌ����^�C�v�F';     -- �c�ƌ����^�C�v
  cv_seisakugun         CONSTANT VARCHAR2(20)  := '����Q�R�[�h';    -- ����Q�R�[�h
  cv_item_product_class CONSTANT VARCHAR2(20)  := '���i���i�敪';    -- ���i���i�敪
  cv_cost_cmpnt_01gen   CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_01gen;   -- ����
  cv_cost_cmpnt_02sai   CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_02sai;   -- �Đ���
  cv_cost_cmpnt_03szi   CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_03szi;   -- ���ޔ�
  cv_cost_cmpnt_04hou   CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_04hou;   -- ���
  cv_cost_cmpnt_05gai   CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_05gai;   -- �O�����H��
  cv_cost_cmpnt_06hkn   CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_06hkn;   -- �ۊǔ�
  cv_cost_cmpnt_07kei   CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_07kei;   -- ���̑��o��
  cv_cost_type1         CONSTANT VARCHAR2(10)  := '�m���';     -- �����^�C�v:�m���
  cv_emargency_flag     CONSTANT VARCHAR2(1)   := '*';          -- �x��
  cv_update_div         CONSTANT VARCHAR2(1)   := 'D';          -- �X�V�敪
  cv_n                  CONSTANT VARCHAR2(1)   := 'N';          -- �K�p�t���O
  cv_apply_date         CONSTANT VARCHAR2(10)  := '9999/99/99'; -- �f�t�H���g���t
  cv_date_fmt_std        CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_date_fmt_std; -- �f�t�H���g���t
  cv_space_1            CONSTANT VARCHAR2(1)   := ' ';          -- �X�y�[�X1��
  cv_space_2            CONSTANT VARCHAR2(2)   := '  ';         -- �X�y�[�X2��
  cv_sep_com            CONSTANT VARCHAR2(1)   := ',';          -- CSV�`���f�[�^��؂蕶��
  cv_csv_file           CONSTANT VARCHAR2(1)   := '0';          -- CSV�t�@�C��
  cv_output_log         CONSTANT VARCHAR2(3)   := 'LOG';
  cv_item_code_from     CONSTANT VARCHAR2(7)   := '0000001';    -- �i���R�[�h�J�n
  cv_item_code_to       CONSTANT VARCHAR2(7)   := '3999999';    -- �i���R�[�h�I��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- CSV�f�[�^�ۑ��p���R�[�h�^�ϐ�
  TYPE g_item_mst_rtype IS RECORD(
    v_seisakugun            VARCHAR2(8),   -- ����Q�R�[�h
    v_item_no               VARCHAR2(7),   -- �i���R�[�h
    v_cmpnt_cost1           VARCHAR2(12),  -- ����
    v_cmpnt_cost2           VARCHAR2(12),  -- �Đ���
    v_cmpnt_cost3           VARCHAR2(12),  -- ���ޔ�
    v_cmpnt_cost4           VARCHAR2(12),  -- ���
    v_cmpnt_cost5           VARCHAR2(12),  -- �O�����H��
    v_cmpnt_cost6           VARCHAR2(12),  -- �ۊǔ�
    v_cmpnt_cost7           VARCHAR2(12),  -- ���̑��o��
    v_cmpnt_cost            VARCHAR2(12),  -- �W�������v
    v_discrete_cost         VARCHAR2(12),  -- �c�ƌ���
    v_emargency_flag        VARCHAR2(6),   -- �x��
    v_update_div            VARCHAR2(10),  -- �X�V�敪
    v_apply_date            VARCHAR2(12),  -- �K�p�J�n��
    v_item_name             VARCHAR2(42),  -- ������
    v_item_short_name       VARCHAR2(22),  -- ����
    v_item_id               VARCHAR2(8)    -- �i��ID
  );
  --
  -- �i�ڏ��i�[�p�e�[�u���^��`
  TYPE g_item_mst_ttype IS TABLE OF g_item_mst_rtype INDEX BY PLS_INTEGER;
  g_item_mst_tab    g_item_mst_ttype;    -- �����z��̒�`
  --
  -- �W�������i�[�p���R�[�h�^�ϐ�
  TYPE g_cost_rtype IS RECORD(
    cmpnt_cost1  cm_cmpt_dtl.cmpnt_cost%TYPE,  -- ����
    cmpnt_cost2  cm_cmpt_dtl.cmpnt_cost%TYPE,  -- �Đ���
    cmpnt_cost3  cm_cmpt_dtl.cmpnt_cost%TYPE,  -- ���ޔ�
    cmpnt_cost4  cm_cmpt_dtl.cmpnt_cost%TYPE,  -- ���
    cmpnt_cost5  cm_cmpt_dtl.cmpnt_cost%TYPE,  -- �O�����H��
    cmpnt_cost6  cm_cmpt_dtl.cmpnt_cost%TYPE,  -- �ۊǔ�
    cmpnt_cost7  cm_cmpt_dtl.cmpnt_cost%TYPE,  -- ���̑��o��
    cmpnt_cost   cm_cmpt_dtl.cmpnt_cost%TYPE   -- �W�������v
  );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date  DATE;          -- �Ɩ����t
  gv_calendar_code VARCHAR2(4);   -- �J�����_�R�[�h
  gv_cost_type     VARCHAR2(10);  -- �R�X�g�^�C�v
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    iv_calendar_code     IN  VARCHAR2,     -- �W�������Ώ۔N�x
    iv_cost_type         IN  VARCHAR2,     -- �c�ƌ����^�C�v
    ov_errbuf            OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step       VARCHAR2(100);   -- �X�e�b�v
    lv_msg_token  VARCHAR2(100);   -- �f�o�b�O�p�g�[�N��
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Ɩ����t�擾
    lv_step      := 'A-1.1';
    lv_msg_token := '�Ɩ����t�擾';
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --���̓p�����[�^�̐ݒ�
    lv_step      := 'A-1.1';
    lv_msg_token := '���̓p�����[�^�̐ݒ�';
    gv_calendar_code := iv_calendar_code;  -- �J�����_�R�[�h
    gv_cost_type     := iv_cost_type;      -- �R�X�g�^�C�v
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    -- ���̓p�����[�^���b�Z�[�W�o�́A���O�o��
    lv_step      := 'A-1.1';
    lv_msg_token := '���̓p�����[�^�o��';
    lv_errmsg    := cv_inp_calendar_code || gv_calendar_code;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    lv_errmsg    := cv_inp_cost_type || gv_cost_type;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : get_cmp_cost
   * Description      : �W�������擾(A-3.1,A-3.2)
   ***********************************************************************************/
  PROCEDURE get_cmp_cost(
    in_item_id            IN  NUMBER,              -- �i��ID
    o_cost_rec            OUT g_cost_rtype,        -- ���R�[�h�^�ϐ�
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cmp_cost'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step       VARCHAR2(100);   -- �X�e�b�v
    lv_msg_token  VARCHAR2(100);   -- �f�o�b�O�p�g�[�N��
    ln_flag       NUMBER;          -- �W���������u0�v�̏ꍇ�𔻒�
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_sum_cost   NUMBER;
    ln_cnt        NUMBER;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    --
    -- �W���������R���|�[�l���gID���ƂɎ擾����
    CURSOR      cnp_cost_cur
    IS
      SELECT    ccmd.cost_cmpntcls_id,
                ccmv.cost_cmpntcls_code,
                ccmd.cmpnt_cost
      FROM      cm_cmpt_dtl          ccmd,
                cm_cldr_dtl          cclr,
                cm_cmpt_mst_vl       ccmv,
                fnd_lookup_values_vl flv
      WHERE     ccmd.calendar_code       = cclr.calendar_code
      AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id
      AND       ccmv.cost_cmpntcls_code  = flv.meaning
      AND       ccmd.item_id             = in_item_id
      AND       ccmd.calendar_code       = gv_calendar_code
      AND       flv.lookup_type          = cv_lookup_cost_cmpt;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �W�������擾(A-3.1)
    -- ===============================
    --
    -- �R���|�[�l���gID���ƂɕW��������ϐ��Ɋi�[����
    -- �W�������𑫂�����
    lv_step := 'A-3';
    --�ϐ�������
    ln_sum_cost := 0;
    ln_cnt      := 0;
    <<cnp_cost_loop>>
    FOR l_cost_rec IN cnp_cost_cur LOOP
      lv_step      := 'A-3.1';
      lv_msg_token := '�W�������擾';
      ln_cnt := ln_cnt + 1;
      --
      CASE
        WHEN ( l_cost_rec.cost_cmpntcls_code = cv_cost_cmpnt_01gen ) THEN
          o_cost_rec.cmpnt_cost1 := l_cost_rec.cmpnt_cost;
          ln_sum_cost := ln_sum_cost + l_cost_rec.cmpnt_cost;
        WHEN ( l_cost_rec.cost_cmpntcls_code = cv_cost_cmpnt_02sai ) THEN
          o_cost_rec.cmpnt_cost2 := l_cost_rec.cmpnt_cost;
          ln_sum_cost := ln_sum_cost + l_cost_rec.cmpnt_cost;
        WHEN ( l_cost_rec.cost_cmpntcls_code = cv_cost_cmpnt_03szi ) THEN
          o_cost_rec.cmpnt_cost3 := l_cost_rec.cmpnt_cost;
          ln_sum_cost := ln_sum_cost + l_cost_rec.cmpnt_cost;
        WHEN ( l_cost_rec.cost_cmpntcls_code = cv_cost_cmpnt_04hou ) THEN
          o_cost_rec.cmpnt_cost4 := l_cost_rec.cmpnt_cost;
          ln_sum_cost := ln_sum_cost + l_cost_rec.cmpnt_cost;
        WHEN ( l_cost_rec.cost_cmpntcls_code = cv_cost_cmpnt_05gai ) THEN
          o_cost_rec.cmpnt_cost5 := l_cost_rec.cmpnt_cost;
          ln_sum_cost := ln_sum_cost + l_cost_rec.cmpnt_cost;
        WHEN ( l_cost_rec.cost_cmpntcls_code = cv_cost_cmpnt_06hkn ) THEN
          o_cost_rec.cmpnt_cost6 := l_cost_rec.cmpnt_cost;
          ln_sum_cost := ln_sum_cost + l_cost_rec.cmpnt_cost;
        WHEN ( l_cost_rec.cost_cmpntcls_code = cv_cost_cmpnt_07kei ) THEN
          o_cost_rec.cmpnt_cost7 := l_cost_rec.cmpnt_cost;
          ln_sum_cost := ln_sum_cost + l_cost_rec.cmpnt_cost;
      END CASE;
    END LOOP cnp_cost_loop;
    --
    -- ===============================
    -- �W�������擾(A-3.2)
    -- ===============================
    --
    -- �������񂾕W��������ϐ��Ɋi�[����
    lv_step      := 'A-3.2';
    lv_msg_token := '�W���������v';
    IF ( ln_cnt > 0 ) THEN
      o_cost_rec.cmpnt_cost := ln_sum_cost;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_cmp_cost;
--
--
  /**********************************************************************************
   * Procedure Name   : get_item_mst
   * Description      : �i�ڏ��擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_item_mst(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_mst'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step       VARCHAR2(100);   -- �X�e�b�v
    lv_msg_token  VARCHAR2(100);   -- �f�o�b�O�p�g�[�N��
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
-- Ver1.2  2009/04/08  Add H.Yoshikawa  ��QNo.T1_0184 �Ή�
    -- �i�ڃX�e�[�^�X�F���o�^
    cn_itm_status_pre_reg    CONSTANT NUMBER := xxcmm_004common_pkg.cn_itm_status_pre_reg;
-- End
--
    -- *** ���[�J���ϐ� ***
    l_cost_rec               g_cost_rtype;  -- �W�������擾�p���R�[�h�^�ϐ�
    ln_c                     NUMBER;        -- �J�E���^
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    --
    -- �i�ڏ����擾����
    CURSOR      item_csv_cur
    IS
      SELECT    xoiv.item_id,
                xoiv.item_no,
                xoiv.item_name,
                xoiv.item_short_name,
                se.seisakugun,
                xoiv.opt_cost_new      discrete_cost
      FROM      xxcmm_opmmtl_items_v   xoiv,
-- Ver1.2  2009/04/08  Del H.Yoshikawa  ��QNo.T1_0184 �Ή�
--                financials_system_parameters fsp,
-- End
               (SELECT      gic_se.item_id       AS item_id
                           ,mcv_se.segment1      AS seisakugun
                           ,mcv_se.description   AS seisakugun_name
                FROM        gmi_item_categories  gic_se
                           ,mtl_category_sets_vl mcsv_se
                           ,mtl_categories_vl    mcv_se
                WHERE       gic_se.category_set_id    = mcsv_se.category_set_id
                AND         mcsv_se.category_set_name = cv_seisakugun
                AND         gic_se.category_id        = mcv_se.category_id
                ) se
      WHERE     xoiv.item_id            = xoiv.parent_item_id
-- Ver1.2  2009/04/08  Mod H.Yoshikawa  ��QNo.T1_0184 �Ή�
--      AND       xoiv.organization_id    = fsp.inventory_organization_id
      AND       xoiv.item_status       >= cn_itm_status_pre_reg
-- End
      AND       xoiv.item_id            = se.item_id(+)
      AND       xoiv.item_no BETWEEN cv_item_code_from AND cv_item_code_to
      AND       xoiv.start_date_active  <= TRUNC( SYSDATE )
      AND       xoiv.end_date_active    >= TRUNC( SYSDATE )
      ORDER BY  se.seisakugun,
                xoiv.item_no;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    --
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �i�ڏ��擾(A-2.1)
    -- ===============================
    --
    -- �擾��������ϐ��Ɋi�[����
    lv_step := 'A-2';
    ln_c := 0;
    --
    <<item_info_loop>>
    FOR lr_item_csv_rec IN item_csv_cur LOOP
      lv_step      := 'A-2.1';
      lv_msg_token := '�i�ڏ��擾';
      ln_c := ln_c + 1;
      g_item_mst_tab(ln_c).v_item_id         := cv_space_1 || TO_CHAR( lr_item_csv_rec.item_id );
      g_item_mst_tab(ln_c).v_item_no         := lr_item_csv_rec.item_no;
      g_item_mst_tab(ln_c).v_item_name       := cv_space_2 || lr_item_csv_rec.item_name;
      g_item_mst_tab(ln_c).v_item_short_name := cv_space_2 || lr_item_csv_rec.item_short_name;
      g_item_mst_tab(ln_c).v_seisakugun      := lr_item_csv_rec.seisakugun;
      --
      -- ===============================
      -- �c�ƌ����擾(A-2.2)
      -- ===============================
      --
      -- �c�ƌ����^�C�v�ʂɉc�ƌ����̎擾���@���ς��
      lv_step      := 'A-2.2';
      lv_msg_token := '�c�ƌ����擾';
      IF ( gv_cost_type = cv_cost_type1 ) THEN    -- �m���
        g_item_mst_tab(ln_c).v_discrete_cost := lr_item_csv_rec.discrete_cost;
        g_item_mst_tab(ln_c).v_apply_date    := cv_apply_date;
      ELSE                                        -- �ۗ�����
        BEGIN
          SELECT    xsibh.discrete_cost,
                    TO_CHAR( xsibh.apply_date, cv_date_fmt_std )
          INTO      g_item_mst_tab(ln_c).v_discrete_cost,
                    g_item_mst_tab(ln_c).v_apply_date
          FROM      ic_item_mst_b            iimb,
                    xxcmm_system_items_b_hst xsibh,
                  ( SELECT   xsibh.item_code,
                             MIN(xsibh.apply_date)    apply_date
                    FROM     xxcmm_system_items_b_hst xsibh
                    WHERE    item_id           =  lr_item_csv_rec.item_id
                    AND      xsibh.apply_date  >= gd_process_date
                    AND      xsibh.apply_flag  =  cv_n
                    GROUP BY xsibh.item_code
                  ) hst
          WHERE     iimb.item_no      =  xsibh.item_code
          AND       xsibh.apply_flag  =  cv_n
          AND       iimb.item_no      =  hst.item_code
          AND       xsibh.apply_date  =  hst.apply_date
          AND       iimb.item_id      =  lr_item_csv_rec.item_id;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN  -- �f�[�^�������ꍇ�A�f�t�H���g�l��ݒ肷��
            g_item_mst_tab(ln_c).v_discrete_cost := NULL;
            g_item_mst_tab(ln_c).v_apply_date    := cv_apply_date;
        END;
      END IF;
      -- =======================================
      -- �W�������擾(A-3.1),�W�������擾(A-3.2)
      -- =======================================
      --
      -- �W���������擾����
      lv_step      := 'A-3.1';
      lv_msg_token := '�W�������擾';
      get_cmp_cost(
        in_item_id    => lr_item_csv_rec.item_id,  -- IN  �i��ID
        o_cost_rec    => l_cost_rec,               -- OUT ���R�[�h�^�ϐ�
        ov_errbuf     => lv_errbuf,                -- OUT �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode    => lv_retcode,               -- OUT ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg     => lv_errmsg);               -- OUT ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF ( lv_retcode != cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
      -- �擾�����W���������R���|�[�l���gID���Ƃɕϐ��Ɋi�[����
      g_item_mst_tab(ln_c).v_cmpnt_cost1     := TO_CHAR( l_cost_rec.cmpnt_cost1 );
      g_item_mst_tab(ln_c).v_cmpnt_cost2     := TO_CHAR( l_cost_rec.cmpnt_cost2 );
      g_item_mst_tab(ln_c).v_cmpnt_cost3     := TO_CHAR( l_cost_rec.cmpnt_cost3 );
      g_item_mst_tab(ln_c).v_cmpnt_cost4     := TO_CHAR( l_cost_rec.cmpnt_cost4 );
      g_item_mst_tab(ln_c).v_cmpnt_cost5     := TO_CHAR( l_cost_rec.cmpnt_cost5 );
      g_item_mst_tab(ln_c).v_cmpnt_cost6     := TO_CHAR( l_cost_rec.cmpnt_cost6 );
      g_item_mst_tab(ln_c).v_cmpnt_cost7     := TO_CHAR( l_cost_rec.cmpnt_cost7 );
      g_item_mst_tab(ln_c).v_cmpnt_cost      := TO_CHAR( l_cost_rec.cmpnt_cost );
      IF ( l_cost_rec.cmpnt_cost IS NULL ) THEN  -- �W�������������ꍇ�A�x����'*'���Z�b�g����
        g_item_mst_tab(ln_c).v_emargency_flag := cv_emargency_flag;
      END IF;
      -- ===============================
      -- �W�������擾(A-3.3)
      -- ===============================
      --
      -- �W�������Ɖc�ƌ������r���A�c�ƌ����̂ق�����������΁A�x����'*'���Z�b�g����
      lv_step      := 'A-3.3';
      lv_msg_token := '�W�������Ɖc�ƌ����̔�r';
      IF ( l_cost_rec.cmpnt_cost > NVL( g_item_mst_tab(ln_c).v_discrete_cost, 0 ) ) THEN
        g_item_mst_tab(ln_c).v_emargency_flag := cv_emargency_flag;
      END IF;
      -- ===============================
      -- �W�������擾(A-3.4)
      -- ===============================
      --
      -- �W�������������_�ȉ��̐��l�������Ă���΁A�x����'*'���Z�b�g����
      lv_step      := 'A-3.4';
      lv_msg_token := '�W�����������_�`�F�b�N';
      IF ( l_cost_rec.cmpnt_cost <> TRUNC( l_cost_rec.cmpnt_cost, 0 ) ) THEN
        g_item_mst_tab(ln_c).v_emargency_flag := cv_emargency_flag;
      END IF;
      -- ===============================
      -- �X�V�敪�ݒ�
      -- ===============================
      --
      -- ���ׂẴ��R�[�h�̍X�V�敪��'D'���Z�b�g����
      lv_step      := 'A-3.5';
      lv_msg_token := '�X�V�敪�ݒ�';
      g_item_mst_tab(ln_c).v_update_div := cv_update_div;
    END LOOP item_info_loop;
    --
-- Ver1.1
--    -- �i�ڂ̑Ώۃf�[�^�������ꍇ�A�Ώۃf�[�^�������b�Z�[�W��\������
--    IF ( ln_c = 0 ) THEN
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name_xxcmm,
--                      iv_name         => cv_msg_xxcmm_00470,
--                      iv_token_name1  => cv_tkn_year,
--                      iv_token_value1 => gv_calendar_code,
--                      iv_token_name2  => cv_tkn_cost_type,
--                      iv_token_value2 => gv_cost_type
--                    );
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.LOG
--        ,buff   => lv_errmsg
--      );
--    END IF;
--
    -- �Ώی���
    gn_target_cnt := ln_c;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_item_mst;
--
--
  /**********************************************************************************
   * Procedure Name   : output_csv�i���[�v���j
   * Description      : CSV�`���f�[�^�o��(A-4,A-5)
   ***********************************************************************************/
  PROCEDURE output_csv(
    iv_file_type      IN  VARCHAR2,            -- �t�@�C�����
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_csv_file     VARCHAR2(5000);        -- �o�͏��
    ln_c            NUMBER;
    lv_step         VARCHAR2(100);   -- �X�e�b�v
    lv_msg_token    VARCHAR2(100);   -- �f�o�b�O�p�g�[�N��
-- Ver1.1
    lv_out_msg      VARCHAR2(2000);
-- End
    --
    -- CSV�`���f�[�^�̃t�B�[���h�����i�[�p�ϐ�
    TYPE arrayitm IS TABLE OF NUMBER(2,0);
    dec_array arrayitm;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���b�N�A�b�v��荀�ڃ^�C�g�����擾����
    CURSOR    lookup_gen_cur
    IS
    SELECT    flv.lookup_type,
              flv.lookup_code,
              flv.meaning,
              flv.attribute1    fld_dec
    FROM      fnd_lookup_values_vl flv
    WHERE     flv.lookup_type = cv_lookup_csv_head
    ORDER BY  flv.lookup_code;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
  --
  BEGIN
--
--################## �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �w�b�_���ڎ擾(A-4.1)
    -- ===============================
    --
    -- CSV�`���f�[�^�̃w�b�_���擾����
    lv_step      := 'A-4.1';
    lv_msg_token := '�w�b�_���ڎ擾';
-- Ver1.1
--    gv_out_msg := xxccp_common_pkg.get_msg(
    lv_out_msg := xxccp_common_pkg.get_msg(
-- End
                     iv_application  => cv_app_name_xxcmm,
                     iv_name         => cv_msg_xxcmm_00472,
                     iv_token_name1  => cv_tkn_year,
                     iv_token_value1 => gv_calendar_code,
                     iv_token_name2  => cv_tkn_cost_type,
                     iv_token_value2 => gv_cost_type
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
-- Ver1.1
--      ,buff   => gv_out_msg
      ,buff   => lv_out_msg
-- End
    );
    --
    -- �ϐ�������
    ln_c := 0;
    lv_csv_file := NULL;
    dec_array := arrayitm();
    dec_array.EXTEND(17);
    --
    -- ===============================
    -- �w�b�_���ڎ擾(A-4.2)
    -- ===============================
    --
    -- CSV�`���f�[�^�̍��ڃ^�C�g�����擾���A�����𐮂���
    lv_step      := 'A-4.2';
    lv_msg_token := 'CSV�`���f�[�^���ڃ^�C�g���擾';
    <<head_info_loop>>
    FOR l_head_info_rec IN lookup_gen_cur LOOP
      ln_c := ln_c + 1;
      CASE
        WHEN ( ln_c = 1 ) THEN  -- ����Q
          lv_step     := 'A-4.2:����Q';
          lv_csv_file := lv_csv_file
                         || RPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 2 ) THEN  -- �i���R�[�h
          lv_step     := 'A-4.2:�i���R�[�h';
          lv_csv_file := lv_csv_file
                         || RPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 3 ) THEN  -- ����
          lv_step     := 'A-4.2:����';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 4 ) THEN  -- �Đ���
          lv_step     := 'A-4.2:�Đ���';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 5 ) THEN  -- ���ޔ�
          lv_step     := 'A-4.2:���ޔ�';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 6 ) THEN  -- ���
          lv_step     := 'A-4.2:���';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 7 ) THEN  -- �O�����H��
          lv_step     := 'A-4.2:�O�����H��';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 8 ) THEN  -- �ۊǔ�
          lv_step     := 'A-4.2:�ۊǔ�';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 9 ) THEN  -- ���̑��o��
          lv_step     := 'A-4.2:���̑��o��';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 10 ) THEN  -- �W�������v
          lv_step     := 'A-4.2:�W�������v';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 11 ) THEN  -- �c�ƌ���
          lv_step     := 'A-4.2:�c�ƌ���';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 12 ) THEN  -- �x��
          lv_step     := 'A-4.2:�x��';
          lv_csv_file := lv_csv_file
                         || RPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 13 ) THEN  -- �X�V�敪
          lv_step     := 'A-4.2:�X�V�敪';
          lv_csv_file := lv_csv_file
                         || RPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 14 ) THEN  -- �K�p�J�n��
          lv_step     := 'A-4.2:�K�p�J�n��';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 15 ) THEN  -- ������
          lv_step     := 'A-4.2:������';
          lv_csv_file := lv_csv_file
                         || RPAD( cv_space_2 || l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 16 ) THEN  -- ����
          lv_step     := 'A-4.2:����';
          lv_csv_file := lv_csv_file
                         || RPAD( cv_space_2 || l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 17 ) THEN  -- �i��ID
          lv_step     := 'A-4.2:�i��ID';
          lv_csv_file := lv_csv_file
                         || RPAD( cv_space_1 || l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
      END CASE;
      dec_array(ln_c) := l_head_info_rec.fld_dec;
    END LOOP head_info_loop;
    --
-- Ver1.1
--    IF ( ln_c = 0 ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_app_name_xxcmm,
--                     iv_name         => cv_msg_xxcmm_00471
--                   );
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.LOG
--        ,buff   => lv_errmsg
--      );
--    END IF;
-- End
    --
    lv_csv_file := SUBSTRB( lv_csv_file, 1, LENGTHB( lv_csv_file ) - 1 );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_file
    );
    --
    -- ===============================
    -- CSV�`���f�[�^�̏o��(A-5)
    -- ===============================
    --
    -- �i�ڏ�񏑎��𐮂��ďo�͂���
    lv_step      := 'A-5';
    lv_msg_token := 'CSV�`���f�[�^�̏o��';
    IF ( g_item_mst_tab.COUNT IS NULL ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
    END IF;
    IF ( g_item_mst_tab.COUNT <> 0 ) THEN
      ln_c := 0;
      <<g_item_mst_tab_loop>>
      FOR ln IN g_item_mst_tab.FIRST .. g_item_mst_tab.LAST LOOP
        ln_c := ln_c + 1;
        lv_csv_file :=    RPAD( NVL( g_item_mst_tab(ln).v_seisakugun, cv_space_1 ),      dec_array(1) )
                       || cv_sep_com   -- ����Q
                       || RPAD( NVL( g_item_mst_tab(ln).v_item_no, cv_space_1 ),         dec_array(2) )
                       || cv_sep_com   -- �i���R�[�h
                       || LPAD( NVL( g_item_mst_tab(ln).v_cmpnt_cost1, cv_space_1 ),     dec_array(3) )
                       || cv_sep_com   -- ����
                       || LPAD( NVL( g_item_mst_tab(ln).v_cmpnt_cost2, cv_space_1 ),     dec_array(4) )
                       || cv_sep_com   -- �Đ���
                       || LPAD( NVL( g_item_mst_tab(ln).v_cmpnt_cost3, cv_space_1 ),     dec_array(5) )
                       || cv_sep_com   -- ���ޔ�
                       || LPAD( NVL( g_item_mst_tab(ln).v_cmpnt_cost4, cv_space_1 ),     dec_array(6) )
                       || cv_sep_com   -- ���
                       || LPAD( NVL( g_item_mst_tab(ln).v_cmpnt_cost5, cv_space_1 ),     dec_array(7) )
                       || cv_sep_com   -- �O�����H��
                       || LPAD( NVL( g_item_mst_tab(ln).v_cmpnt_cost6, cv_space_1 ),     dec_array(8) )
                       || cv_sep_com   -- �ۊǔ�
                       || LPAD( NVL( g_item_mst_tab(ln).v_cmpnt_cost7, cv_space_1 ),     dec_array(9) )
                       || cv_sep_com   -- ���̑��o��
                       || LPAD( NVL( g_item_mst_tab(ln).v_cmpnt_cost, cv_space_1 ),      dec_array(10) )
                       || cv_sep_com   -- �W���������v
                       || LPAD( NVL( g_item_mst_tab(ln).v_discrete_cost, cv_space_1 ),   dec_array(11) )
                       || cv_sep_com   -- �c�ƌ���
                       || RPAD( NVL( g_item_mst_tab(ln).v_emargency_flag, cv_space_1 ),  dec_array(12) )
                       || cv_sep_com   -- �x��
                       || RPAD( NVL( g_item_mst_tab(ln).v_update_div, cv_space_1 ),      dec_array(13) )
                       || cv_sep_com   -- �X�V�敪
                       || LPAD( NVL( g_item_mst_tab(ln).v_apply_date, cv_space_1 ),      dec_array(14) )
                       || cv_sep_com   -- �K�p�J�n��
                       || RPAD( NVL( g_item_mst_tab(ln).v_item_name, cv_space_1 ),       dec_array(15) )
                       || cv_sep_com   -- ������
                       || RPAD( NVL( g_item_mst_tab(ln).v_item_short_name, cv_space_1 ), dec_array(16) )
                       || cv_sep_com   -- ����
                       || RPAD( NVL( g_item_mst_tab(ln).v_item_id, cv_space_1 ),         dec_array(17) )
                       ;               -- �i��ID
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_csv_file
        );
-- Ver1.1
--        -- ��������
--        gn_normal_cnt := ln_c;
-- End
      END LOOP g_item_mst_tab_loop;
      --
      -- ��������
      gn_normal_cnt := ln_c;
-- Ver1.1
--      IF ( ln_c = 0 ) THEN
--        FND_FILE.PUT_LINE(
--           which  => FND_FILE.LOG
--          ,buff   => lv_errmsg
--        );
--      END IF;
-- End
    END IF;
  --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[����
      gn_error_cnt := ln_c;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_csv;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_calendar_code     IN  VARCHAR2,     --   �W�������Ώ۔N�x
    iv_cost_type         IN  VARCHAR2,     --   �c�ƌ����^�C�v
    ov_errbuf            OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_step           VARCHAR2(100);   -- �X�e�b�v
    lv_msg_token      VARCHAR2(100);   -- �f�o�b�O�p�g�[�N��
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    subprog_err_expt  EXCEPTION;
    --
  BEGIN
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
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    lv_step      := 'A-1';
    lv_msg_token := '��������';
    proc_init(
      iv_calendar_code  => iv_calendar_code,  -- �W�������Ώ۔N�x
      iv_cost_type      => iv_cost_type,      -- �c�ƌ����^�C�v
      ov_errbuf         => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode        => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE subprog_err_expt;
    END IF;
    -- ===================================
    -- �i�ڏ��擾(A-2),�W�������擾(A-3)
    -- ===================================
    lv_step      := 'A-2,A-3';
    lv_msg_token := '�i�ڏ��A�W�������擾';
    get_item_mst(
      ov_errbuf    => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode   => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg    => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE subprog_err_expt;
    END IF;
    -- ==========================================
    -- �w�b�_���ڎ擾(A-4),CSV�`���f�[�^�o��(A-5)
    -- ==========================================
    lv_step      := 'A-4,A-5';
    lv_msg_token := '�w�b�_���ڎ擾�ACSV�`���f�[�^�o��';
    output_csv(
      iv_file_type => cv_csv_file,       -- CSV�t�@�C��
      ov_errbuf    => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode   => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg    => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE subprog_err_expt;
    END IF;
--
--
  EXCEPTION
    WHEN subprog_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    --
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_msg_token --���[�U�[�E�G���[���b�Z�[�W
      );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf            OUT VARCHAR2,    -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT VARCHAR2,    -- ���^�[���E�R�[�h    --# �Œ� #
    iv_calendar_code  IN  VARCHAR2,    -- �W�������Ώ۔N�x
    iv_cost_type      IN  VARCHAR2     -- �c�ƌ����^�C�v
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
    lv_step            VARCHAR2(100);   -- �X�e�b�v
    lv_msg_token       VARCHAR2(100);   -- �f�o�b�O�p�g�[�N��
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    lv_step      := 'submain';
    submain(
       iv_calendar_code  => iv_calendar_code,  -- �W�������Ώ۔N�x
       iv_cost_type      => iv_cost_type,      -- �c�ƌ����^�C�v
       ov_errbuf         => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ov_retcode        => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
       ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    lv_step      := 'A-6:err';
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
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --�Ώی����o��
    lv_step      := 'A-6:�Ώی����o��';
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
    lv_step      := 'A-6:���������o��';
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
    lv_step      := 'A-6:�G���[�����o��';
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
    --�I�����b�Z�[�W
    lv_step      := 'A-6:�I�����b�Z�[�W';
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
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
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCMM004A06C;
/
