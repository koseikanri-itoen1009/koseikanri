CREATE OR REPLACE PACKAGE BODY APPS.XXCSO019A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A08C(body)
 * Description      : �v���̔��s��ʂ���A�c�ƈ����ƂɎw������܂ތ���1���`�w����܂�
 *                    �K����т̖����ڋq��\�����܂��B
 * MD.050           : MD050_CSO_019_A08_���K��ڋq�ꗗ�\
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  chk_param              �p�����[�^�E�`�F�b�N(A-2)
 *  process_data           �f�[�^���H(A-4)
 *  insert_row             ���[�N�e�[�u���f�[�^�o�^(A-5)
 *  update_row             �c�ƈ��ʌ����v�����[�N�e�[�u���f�[�^�o�^(A-6)
 *  act_svf                SVF�N��(A-7)
 *  delete_row             ���[�N�e�[�u���f�[�^�폜(A-8)
 *  submain                ���C�������v���V�[�W��
 *                           �f�[�^�擾(A-3)
 *                           SVF�N��API�G���[�`�F�b�N(A-9)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������(A-10)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-12    1.0   Ryo.Oikawa       �V�K�쐬
 *  2009-03-03    1.1   Kazuyo.Hosoi     SVF�N��API���ߍ���
 *  2009-03-11    1.1   Kazuyo.Hosoi     �y��Q�Ή�047�z�ڋq�敪�A�X�e�[�^�X���o�����ύX
 *  2009-03-19    1.1   Mio.Maruyama     �y��Q�Ή�070�zSVF�N���֐��R�[���ʒu�C��(submain)
 *  2009-04-22    1.2   Daisuke.Abe      �yT1_0680�z���[�gNO�Ή�
 *  2009-05-01    1.3   Tomoko.Mori      T1_0897�Ή�
 *  2009-05-14    1.4   Makoto.Ohtsuki   �yT1_0790�z�o�͏����̕ύX
 *  2009-05-20    1.5   Makoto.Ohtsuki   �r�s��Q�Ή�(T1_0696)
 *  2009-06-03    1.6   Kazuo.Satomura   �r�s��Q�Ή�(T1_0696 SQLERRM���폜)
 *  2009-06-04    1.7   Kazuo.Satomura   �r�s��Q�Ή�(T1_1329)
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO019A08C';  -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- �A�v���P�[�V�����Z�k��
  cv_ref_app_name        CONSTANT VARCHAR2(5)   := 'XXCMM';         -- �Q�ƃR�[�h�p�A�v���P�[�V�����Z�k��
  cn_org_id              CONSTANT NUMBER        := TO_NUMBER(SUBSTRB(USERENV('CLIENT_INFO'), 1, 10)); -- ���O�C���g�D�h�c
  --
  cv_report_id           CONSTANT VARCHAR2(30)  := 'XXCSO019A08C';  -- ���[ID
  -- ���t����
  cv_format_date_ymd1    CONSTANT VARCHAR2(8)   := 'YYYYMMDD';      -- ���t�t�H�[�}�b�g�i�N�����j
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00129';  -- �p�����[�^�o��
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00005';  -- �K�{���ڃG���[
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00042';  -- �c�a�o�^�E�X�V�G���[
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00135';  -- API�G���[���b�Z�[�W
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00140';  -- ����0�����b�Z�[�W
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00132';  -- �N�����̌^�Ⴂ���b�Z�[�W
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00157';  -- �N�����̖��������b�Z�[�W
      /* 20090514_Ohtsuki_T1_0790 START*/
  cv_tkn_number_10       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[���b�Z�[�W
      /* 20090514_Ohtsuki_T1_0790 END  */
  -- �g�[�N���R�[�h
  cv_tkn_param_nm        CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  cv_tkn_val             CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_clmn            CONSTANT VARCHAR2(20) := 'COLUMN';
  cv_tkn_param1          CONSTANT VARCHAR2(20) := 'PARAM1';
  cv_tkn_act             CONSTANT VARCHAR2(20) := 'ACTION';
  cv_tkn_errmsg          CONSTANT VARCHAR2(20) := 'ERRMSG';
  cv_tkn_tbl             CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_api_nm          CONSTANT VARCHAR2(20) := 'API_NAME';
  cv_tkn_entry           CONSTANT VARCHAR2(20) := 'ENTRY';
      /* 20090514_Ohtsuki_T1_0790 START*/
  cv_tkn_prof_nm         CONSTANT VARCHAR2(20) := 'PROF_NAME';
      /* 20090514_Ohtsuki_T1_0790 END  */
  --
  cv_msg_prnthss_l       CONSTANT VARCHAR2(1)  := '(';
  cv_msg_prnthss_r       CONSTANT VARCHAR2(1)  := ')';
  cv_msg_comma           CONSTANT VARCHAR2(1)  := ',';
  --
  cn_user_id             CONSTANT NUMBER       := fnd_global.user_id;           -- ���[�U�[ID
  cn_resp_id             CONSTANT NUMBER       := fnd_global.resp_id;           -- �E��ID
  cd_sysdate             CONSTANT DATE         := SYSDATE;                      -- SYSDATE
  cv_rep_tp              CONSTANT VARCHAR2(1)  := '1';                          -- ���[�^�C�v
  cv_true                CONSTANT VARCHAR2(4)  := 'TRUE';                       -- �߂�l���f�p
  cv_false               CONSTANT VARCHAR2(5)  := 'FALSE';                      -- �߂�l���f�p
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���K��ڋq�ꗗ�\���[���[�N�e�[�u�� �f�[�^�i�[�p���R�[�h�^��`
  TYPE g_rp_nov_data_rtype IS RECORD(
     line_num                      xxcso_rep_novisit.line_num%TYPE                     -- �s�ԍ�
    ,report_id                     xxcso_rep_novisit.report_id%TYPE                    -- ���[�h�c
    ,report_name                   xxcso_rep_novisit.report_name%TYPE                  -- ���[�^�C�g��
    ,output_date                   xxcso_rep_novisit.output_date%TYPE                  -- �o�͓���
    ,base_date                     xxcso_rep_novisit.base_date%TYPE                    -- ��N����
    ,base_date_start               xxcso_rep_novisit.base_date_start%TYPE              -- ���START
    ,base_date_end                 xxcso_rep_novisit.base_date_end%TYPE                -- ���END
    ,base_code                     xxcso_rep_novisit.base_code%TYPE                    -- ���_�R�[�h
    ,hub_name                      xxcso_rep_novisit.hub_name%TYPE                     -- ���_����
    ,employee_number               xxcso_rep_novisit.employee_number%TYPE              -- �c�ƈ��R�[�h
    ,employee_name                 xxcso_rep_novisit.employee_name%TYPE                -- �c�ƈ���
    ,total_count                   xxcso_rep_novisit.total_count%TYPE                  -- �������v�^�����v
    ,route_no                      xxcso_rep_novisit.route_no%TYPE                     -- ���[�gNo.
    ,visit_times                   xxcso_rep_novisit.visit_times%TYPE                  -- �K���
    ,account_number                xxcso_rep_novisit.account_number%TYPE               -- �ڋq�R�[�h
    ,account_name                  xxcso_rep_novisit.account_name%TYPE                 -- �ڋq��
    ,final_call_date               xxcso_rep_novisit.final_call_date%TYPE              -- �ŏI�K���
    ,final_tran_date               xxcso_rep_novisit.final_tran_date%TYPE              -- �ŏI�����
    ,business_low_type             xxcso_rep_novisit.business_low_type%TYPE            -- �Ƒԁi�����ށj
    ,mc_flag                       xxcso_rep_novisit.mc_flag%TYPE                      -- �l�b�t���O
    ,created_by                    xxcso_rep_novisit.created_by%TYPE                   -- �쐬��
    ,creation_date                 xxcso_rep_novisit.creation_date%TYPE                -- �쐬��
    ,last_updated_by               xxcso_rep_novisit.last_updated_by%TYPE              -- �ŏI�X�V��
    ,last_update_date              xxcso_rep_novisit.last_update_date%TYPE             -- �ŏI�X�V��
    ,last_update_login             xxcso_rep_novisit.last_update_login%TYPE            -- �ŏI�X�V���O�C��
    ,request_id                    xxcso_rep_novisit.request_id%TYPE                   -- �v��ID
    ,program_application_id        xxcso_rep_novisit.program_application_id%TYPE       -- �ݶ�����۸��ѱ��ع����
    ,program_id                    xxcso_rep_novisit.program_id%TYPE                   -- �ݶ�����۸��тh�c
    ,program_update_date           xxcso_rep_novisit.program_update_date%TYPE          -- ��۸��эX�V��
  );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_current_date     IN  VARCHAR2         -- ���
    ,ov_employee_number  OUT NOCOPY VARCHAR2  -- �]�ƈ��R�[�h
    ,ov_employee_name    OUT NOCOPY VARCHAR2  -- ��������
    ,ov_work_base_code   OUT NOCOPY VARCHAR2  -- �Ζ��n���_�R�[�h
    ,ov_hub_name         OUT NOCOPY VARCHAR2  -- �Ζ��n���_��
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- *** ���[�J���ϐ� ***
    lt_employee_number    xxcso_employees_v2.employee_number%TYPE;  -- �]�ƈ��R�[�h
    lt_last_name          xxcso_employees_v2.last_name%TYPE;        -- ������
    lt_first_name         xxcso_employees_v2.first_name%TYPE;       -- ������
    lv_work_base_code     VARCHAR2(150);                            -- �Ζ��n���_�R�[�h
    lv_work_base_name     VARCHAR2(4000);                           -- �Ζ��n���_��
    -- ���b�Z�[�W�o�͗p
    lv_msg_crnt_dt       VARCHAR2(5000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- ���̓p�����[�^���b�Z�[�W�o��
    -- ===========================
    -- ��s�̑}��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    -- ���b�Z�[�W�擾(���)
    lv_msg_crnt_dt := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_01      --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_entry          --�g�[�N���R�[�h1
                       ,iv_token_value1 => iv_current_date       --�g�[�N���l1
                     );
--
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg_crnt_dt
    );
    -- ===========================
    -- ���O�C�����[�U�[���擾
    -- ===========================
--
    BEGIN
      SELECT  xev.employee_number                               -- �]�ƈ��R�[�h
             ,xev.last_name                                     -- ������
             ,xev.first_name                                    -- ������
             ,xxcso_util_common_pkg.get_emp_parameter(
                xev.work_base_code_new
               ,xev.work_base_code_old
               ,xev.issue_date
               ,TRUNC(xxcso_util_common_pkg.get_online_sysdate)
              ) Work_base_code                                  -- �Ζ��n���_�R�[�h
             ,xxcso_util_common_pkg.get_emp_parameter(
                xev.work_base_name_new
               ,xev.work_base_name_old
               ,xev.issue_date
               ,TRUNC(xxcso_util_common_pkg.get_online_sysdate)
              ) Work_base_name                                  -- �Ζ��n���_��
      INTO    lt_employee_number
             ,lt_last_name
             ,lt_first_name
             ,lv_work_base_code
             ,lv_work_base_name
      FROM    xxcso_employees_v2  xev                          -- �]�ƈ��}�X�^�i�ŐV�j�r���[
      WHERE   xev.user_id = cn_user_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    -- OUT�p�����[�^�̐ݒ�
    ov_employee_number := lt_employee_number;  -- �]�ƈ��R�[�h
    ov_employee_name   := SUBSTRB(lt_last_name || lt_first_name, 1, 40);  -- ��������
    ov_work_base_code  := lv_work_base_code;   -- �Ζ��n���_�R�[�h
    ov_hub_name        := lv_work_base_name;   -- �Ζ��n���_��
--
    -- ��s�̑}��
    fnd_file.put_line(
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
   * Procedure Name   : chk_param
   * Description      : �p�����[�^�E�`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE chk_param(
     iv_current_date     IN  VARCHAR2         -- ���
    ,od_current_date     OUT DATE             -- ���(DATE�^)
    ,od_first_date       OUT DATE             -- ����̌���(DATE�^)
    ,ov_emp_chk_cd       OUT VARCHAR2         -- �c�ƈ��`�F�b�N�l
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chk_param';   -- �v���O������
    cv_first                CONSTANT VARCHAR2(100)   := '01';          -- ����
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- *** ���[�J���萔 ***
    cv_crnt_dt          CONSTANT VARCHAR2(100)   := '���';
    cv_first_dt         CONSTANT VARCHAR2(100)   := '����̌���';
      /* 20090514_Ohtsuki_T1_0790 START*/
    cv_emp_flg           CONSTANT VARCHAR2(100) := 'XXCSO1_ALL_EMP_SEL_FLG_08C';                    -- XXCSO:�z���]�ƈ��o�͉\�t���O
    cv_emp_flg_yes       CONSTANT VARCHAR2(30) := 'Y';
      /* 20090514_Ohtsuki_T1_0790 END  */
    -- *** ���[�J���ϐ� ***
    ld_sysdate          DATE;                  -- �V�X�e�����t
    ld_current_date     DATE;                  -- ���
    ld_first_date       DATE;                  -- ����̌���
    lv_retcd            VARCHAR2(5);           -- ���ʊ֐��߂�l�i�[
      /* 20090514_Ohtsuki_T1_0790 START*/
    lv_emp_flg           VARCHAR2(10);                                                              -- �v���t�@�C���擾�p
      /* 20090514_Ohtsuki_T1_0790 END  */
    -- ���b�Z�[�W�o�͗p
    lv_msg              VARCHAR2(5000);
    -- *** ���[�J����O ***
    chk_param_expt   EXCEPTION;  -- ��������̓G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- �p�����[�^�K�{�`�F�b�N
    -- ===========================
    IF (iv_current_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_02      --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_clmn           --�g�[�N���R�[�h1
                    ,iv_token_value1 => cv_crnt_dt            --�g�[�N���l1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE chk_param_expt;
    END IF;
    -- ===========================
    -- �p�����[�^�i����j�`�F�b�N
    -- ===========================
    ld_sysdate := TRUNC(xxcso_util_common_pkg.get_online_sysdate);
--
    BEGIN
      SELECT TO_DATE(iv_current_date, cv_format_date_ymd1)   current_date  -- IN�p�����[�^���
      INTO   ld_current_date
      FROM   dual
      WHERE  TO_DATE(iv_current_date, cv_format_date_ymd1) <= ld_sysdate
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_09    --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_entry        --�g�[�N���R�[�h1
                       ,iv_token_value1 => cv_crnt_dt          --�g�[�N���l1
                     );
        /* 2009.06.03 K.Satomura T1_0696�Ή� START */
        --lv_errbuf := lv_errmsg || SQLERRM;
        lv_errbuf := lv_errmsg;
        /* 2009.06.03 K.Satomura T1_0696�Ή� END */
        RAISE chk_param_expt;
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_08    --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_entry        --�g�[�N���R�[�h1
                       ,iv_token_value1 => cv_crnt_dt          --�g�[�N���l1
                     );
        /* 2009.06.03 K.Satomura T1_0696�Ή� START */
        --lv_errbuf := lv_errmsg || SQLERRM;
        lv_errbuf := lv_errmsg;
        /* 2009.06.03 K.Satomura T1_0696�Ή� END */
        RAISE chk_param_expt;
    END;
--
    BEGIN
      SELECT TO_DATE(TO_CHAR(ld_current_date,'YYYYMM')||cv_first,'YYYYMMDD')   first_date  -- IN�p�����[�^���
      INTO   ld_first_date
      FROM   dual
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_08    --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_entry        --�g�[�N���R�[�h1
                       ,iv_token_value1 => cv_first_dt         --�g�[�N���l1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE chk_param_expt;
    END;
--
    -- ===========================
    -- �]�ƈ��R�[�h����
    -- ===========================
      /* 20090514_Ohtsuki_T1_0790 START*/
--    lv_retcd   := xxcso_util_common_pkg.chk_responsibility(
--                    in_user_id     => cn_user_id       -- ���O�C�����[�U�h�c
--                   ,in_resp_id     => cn_resp_id       -- �E�ʂh�c
--                   ,iv_report_type => cv_rep_tp        -- ���[�^�C�v�i1:�c�ƈ��ʁA2:�c�ƈ��O���[�v�ʁA���̑��͎w��s�j
--                  );
--��������������������������������������������������������������������������������������������������
-- �v���t�@�C���l�擾
    lv_emp_flg := FND_PROFILE.VALUE(cv_emp_flg);
--
    IF (lv_emp_flg IS NULL) THEN                                                                    -- �v���t�@�C���̎擾�Ɏ��s�����ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_app_name                          -- �A�v���P�[�V�����Z�k��
                                           ,iv_name         => cv_tkn_number_10                     -- ���b�Z�[�W�R�[�h
                                           ,iv_token_name1  => cv_tkn_prof_nm                       -- �g�[�N���R�[�h
                                           ,iv_token_value1 => cv_emp_flg                           -- �g�[�N���l
                                           );
      lv_errbuf := lv_errmsg;
      RAISE chk_param_expt;
    END IF;
--
    IF (lv_emp_flg = cv_emp_flg_yes) THEN                                                           -- �o�͉\�t���O = 'Y'�̏ꍇ
      lv_retcd := cv_false;
    ELSE
      lv_retcd := cv_true;
    END IF;
      /* 20090514_Ohtsuki_T1_0790 END*/
    -- OUT�p�����[�^�̐ݒ�
    od_current_date      := ld_current_date;    -- ���
    od_first_date        := ld_first_date;      -- ����̌���
    ov_emp_chk_cd        := lv_retcd;           -- �c�ƈ��`�F�b�N�l
    -- ��s�̑}��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
    -- *** �p�����[�^�`�F�b�N�G���[ ***
    WHEN chk_param_expt THEN
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
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   : process_data
   * Description      : �f�[�^���H(A-4)
   ***********************************************************************************/
  PROCEDURE process_data(
     io_rp_nov_dt_rec      IN OUT NOCOPY g_rp_nov_data_rtype      -- ���K��ڋq�f�[�^
    ,iv_account_sts        IN  VARCHAR2                           -- �ڋq�X�e�[�^�X�i�\�[�g�p�j
    ,ov_errbuf             OUT NOCOPY VARCHAR2                    -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode            OUT NOCOPY VARCHAR2                    -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg             OUT NOCOPY VARCHAR2                    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'process_data';  -- �v���O������
    cv_sort_type1           CONSTANT VARCHAR2(1)     := '1';  -- �\�[�g�^�C�v
    cv_zero                 CONSTANT VARCHAR2(1)     := '0';  -- �u0�v
    cv_one                  CONSTANT VARCHAR2(1)     := '1';  -- �u1�v
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �N�C�b�N�R�[�h�擾
    cv_lkup_tp_cst_kkyaku_sts       CONSTANT VARCHAR2(30) := 'XXCMM_CUST_KOKYAKU_STATUS';
    cv_yes                          CONSTANT VARCHAR2(30) := 'Y';
    -- ���b�Z�[�W�o�͗p�g�[�N��
    cv_tkn_party_name               CONSTANT VARCHAR2(100) := '�ڋq�X�e�[�^�X����';
    cv_tkn_mc                       CONSTANT VARCHAR2(100) := '�l�b';
    -- *** ���[�J���ϐ� ***
    lv_route_no              xxcso_in_route_no.route_no%TYPE;    -- ���[�gNO
    lv_mc_flag               VARCHAR2(1);          -- �l�b�t���O
    ln_visit_times           NUMBER;               -- �K���
    ld_sysdate               DATE;                 -- �V�X�e�����t
    -- ���b�Z�[�W�i�[�p
    lv_msg                   VARCHAR2(5000);
    -- �x�����b�Z�[�W�o�͔��f�t���O
    lv_msg_flg               BOOLEAN DEFAULT FALSE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �V�X�e�����t��ҏW���A�i�[
    ld_sysdate := TRUNC(xxcso_util_common_pkg.get_online_sysdate);
--
    -- ===========================
    -- ���[�gNO�A�l�b�t���O�擾
    -- ===========================
    IF ( iv_account_sts  = cv_sort_type1 ) THEN
      lv_route_no := io_rp_nov_dt_rec.route_no;
      lv_mc_flag  := cv_zero;
      /* 20090422_abe_T1_0680 START*/
      IF ( lv_route_no IS NOT NULL ) THEN
      /* 20090422_abe_T1_0680 END*/
        -- ===========================
        -- �K��񐔎擾
        -- ===========================
        xxcso_route_common_pkg.calc_visit_times(
           it_route_number  => lv_route_no
          ,on_times         => ln_visit_times
          ,ov_errbuf        => lv_errbuf
          ,ov_retcode       => lv_retcode
          ,ov_errmsg        => lv_errmsg
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_others_expt;
        END IF;
      /* 20090422_abe_T1_0680 START*/
      END IF;
      /* 20090422_abe_T1_0680 END*/
    ELSE
      lv_route_no    := cv_tkn_mc;
      lv_mc_flag     := cv_one;
      ln_visit_times := NULL;
    END IF;
--
    -- ====================================
    -- �擾�l��OUT�p�����[�^�ɐݒ�
    -- ====================================
    io_rp_nov_dt_rec.route_no              := lv_route_no;                -- ���[�gNO
    io_rp_nov_dt_rec.mc_flag               := lv_mc_flag;                 -- �l�b�t���O
    io_rp_nov_dt_rec.visit_times           := ln_visit_times;             -- �K���
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
  END process_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_row
   * Description      : ���[�N�e�[�u���f�[�^�o�^(A-5)
   ***********************************************************************************/
  PROCEDURE insert_row(
     i_rp_nov_dt_rec        IN  g_rp_nov_data_rtype      -- ���K��ڋq�f�[�^
    ,ov_errbuf              OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_row';     -- �v���O������
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
    cv_report_name        CONSTANT VARCHAR2(40)  := '�ᖢ�K��ڋq�ꗗ�\��'; -- ���[�^�C�g��
    cv_tkn_tbl_nm         CONSTANT VARCHAR2(100) := '���K��ڋq�ꗗ�\���[���[�N�e�[�u���̓o�^';
    -- *** ���[�J����O ***
    insert_row_expt     EXCEPTION;          -- ���[�N�e�[�u���o�͏�����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ======================
    -- CSV�o�͏��� 
    -- ======================
    BEGIN
      -- ���[�N�e�[�u���o��
      INSERT INTO xxcso_rep_novisit
        ( line_num                     -- �s�ԍ�
         ,report_id                    -- ���[�h�c
         ,report_name                  -- ���[�^�C�g��
         ,output_date                  -- �o�͓���
         ,base_date                    -- ��N����
         ,base_date_start              -- ���START
         ,base_date_end                -- ���END
         ,base_code                    -- ���_�R�[�h
         ,hub_name                     -- ���_����
         ,employee_number              -- �]�ƈ��R�[�h
         ,employee_name                -- �]�ƈ���
         ,total_count                  -- �������v�^�����v
         ,route_no                     -- ���[�gNO.
         ,visit_times                  -- �K���
         ,account_number               -- �ڋq�R�[�h
         ,account_name                 -- �ڋq��
         ,final_call_date              -- �ŏI�K���
         ,final_tran_date              -- �ŏI�����
         ,business_low_type            -- �Ƒԁi�����ށj
         ,mc_flag                      -- �l�b�t���O
         ,created_by                   -- �쐬��
         ,creation_date                -- �쐬��
         ,last_updated_by              -- �ŏI�X�V��
         ,last_update_date             -- �ŏI�X�V��
         ,last_update_login            -- �ŏI�X�V���O�C��
         ,request_id                   -- �v���h�c        
         ,program_application_id       -- �ݶ�����۸��ѱ��ع����
         ,program_id                   -- �ݶ�����۸��тh�c
         ,program_update_date          -- ��۸��эX�V��
        )
      VALUES
        ( i_rp_nov_dt_rec.line_num                     -- �s�ԍ�
         ,cv_report_id                                 -- ���[�h�c
         ,cv_report_name                               -- ���[�^�C�g��
         ,cd_sysdate                                   -- �o�͓���
         ,i_rp_nov_dt_rec.base_date                    -- ��N����
         ,i_rp_nov_dt_rec.base_date_start              -- ���START
         ,i_rp_nov_dt_rec.base_date_end                -- ���END
         ,i_rp_nov_dt_rec.base_code                    -- ���_�R�[�h
         ,i_rp_nov_dt_rec.hub_name                     -- ���_����
         ,i_rp_nov_dt_rec.employee_number              -- �]�ƈ��R�[�h
         ,i_rp_nov_dt_rec.employee_name                -- �]�ƈ���
         ,i_rp_nov_dt_rec.total_count                  -- �������v�^�����v
         ,i_rp_nov_dt_rec.route_no                     -- ���[�gNO.
         ,i_rp_nov_dt_rec.visit_times                  -- �K���
         ,i_rp_nov_dt_rec.account_number               -- �ڋq�R�[�h
         ,i_rp_nov_dt_rec.account_name                 -- �ڋq��
         ,i_rp_nov_dt_rec.final_call_date              -- �ŏI�K���
         ,i_rp_nov_dt_rec.final_tran_date              -- �ŏI�����
         ,i_rp_nov_dt_rec.business_low_type            -- �Ƒԁi�����ށj
         ,i_rp_nov_dt_rec.mc_flag                      -- �l�b�t���O
         ,i_rp_nov_dt_rec.created_by                   -- �쐬��
         ,i_rp_nov_dt_rec.creation_date                -- �쐬��
         ,i_rp_nov_dt_rec.last_updated_by              -- �ŏI�X�V��
         ,i_rp_nov_dt_rec.last_update_date             -- �ŏI�X�V��
         ,i_rp_nov_dt_rec.last_update_login            -- �ŏI�X�V���O�C��
         ,i_rp_nov_dt_rec.request_id                   -- �v���h�c        
         ,i_rp_nov_dt_rec.program_application_id       -- �ݶ�����۸��ѱ��ع����
         ,i_rp_nov_dt_rec.program_id                   -- �ݶ�����۸��тh�c
         ,i_rp_nov_dt_rec.program_update_date          -- ��۸��эX�V��
        );
--
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_04        --���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_act              --�g�[�N���R�[�h1
                 ,iv_token_value1 => cv_tkn_tbl_nm           --�g�[�N���l1
                 ,iv_token_name2  => cv_tkn_errmsg           --�g�[�N���R�[�h2
                 ,iv_token_value2 => SQLERRM                 --�g�[�N���l2
                );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_row_expt;
    END;
--
  EXCEPTION
    -- *** ���[�N�e�[�u���o�͏�����O ***
    WHEN insert_row_expt THEN
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
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_row;
--
  /**********************************************************************************
   * Procedure Name   : update_row
   * Description      : �c�ƈ��ʌ����v�����[�N�e�[�u���f�[�^�o�^(A-6)
   ***********************************************************************************/
  PROCEDURE update_row(
     iv_employee_number     IN  VARCHAR2                 -- �]�ƈ��ԍ�
    ,in_emp_cnt             IN  NUMBER                   -- ����
    ,ov_errbuf              OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'update_row';     -- �v���O������
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
    cv_tkn_tbl_nm         CONSTANT VARCHAR2(100) := '���K��ڋq�ꗗ�\���[���[�N�e�[�u���̍X�V';
    -- *** ���[�J����O ***
    update_row_expt     EXCEPTION;          -- ���[�N�e�[�u���o�͏�����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ======================
    -- CSV�o�͏��� 
    -- ======================
    BEGIN
      -- ���[�N�e�[�u���o��
      UPDATE  xxcso_rep_novisit
        SET   total_count = in_emp_cnt
        /* 2009.06.04 K.Satomura T1_1329�Ή� START */
        --WHERE employee_number = iv_employee_number;
        WHERE employee_number = iv_employee_number
        AND   request_id      = cn_request_id
        ;
        /* 2009.06.04 K.Satomura T1_1329�Ή� END */
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_04        --���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_act              --�g�[�N���R�[�h1
                 ,iv_token_value1 => cv_tkn_tbl_nm           --�g�[�N���l1
                 ,iv_token_name2  => cv_tkn_errmsg           --�g�[�N���R�[�h2
                 ,iv_token_value2 => SQLERRM                 --�g�[�N���l2
                );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE update_row_expt;
    END;
--
  EXCEPTION
    -- *** ���[�N�e�[�u���o�͏�����O ***
    WHEN update_row_expt THEN
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
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_row;
--
  /**********************************************************************************
   * Procedure Name   : act_svf
   * Description      : SVF�N��(A-7)
   ***********************************************************************************/
  PROCEDURE act_svf(
     ov_errbuf              OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'act_svf';     -- �v���O������
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
    cv_tkn_api_nm_svf CONSTANT  VARCHAR2(20) := 'SVF�N��';
    cv_svf_form_name  CONSTANT  VARCHAR2(20) := 'XXCSO019A08S.xml';  -- �t�H�[���l���t�@�C����
    cv_svf_query_name CONSTANT  VARCHAR2(20) := 'XXCSO019A08S.vrq';  -- �N�G���[�l���t�@�C����
    cv_output_mode    CONSTANT  VARCHAR2(1)   := '1';  
    -- *** ���[�J���ϐ� ***
    lv_svf_file_name   VARCHAR2(50);
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ======================
    -- SVF�N������ 
    -- ======================
    -- �t�@�C�����̐ݒ�
    lv_svf_file_name := cv_pkg_name
                     || TO_CHAR (cd_creation_date, cv_format_date_ymd1)
                     || TO_CHAR (cn_request_id);
--
    BEGIN
      SELECT  user_concurrent_program_name,
              xx00_global_pkg.user_name   ,
              xx00_global_pkg.resp_name
      INTO    lv_conc_name,
              lv_user_name,
              lv_resp_name
      FROM    fnd_concurrent_programs_tl
      WHERE   concurrent_program_id =cn_request_id
      AND     LANGUAGE = 'JA'
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_conc_name := cv_pkg_name;
    END;
--
    lv_file_id := cv_pkg_name;
--
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,iv_conc_name    => lv_conc_name          -- �R���J�����g��
     ,iv_file_name    => lv_svf_file_name      -- �o�̓t�@�C����
     ,iv_file_id      => lv_file_id            -- ���[ID
     ,iv_output_mode  => cv_output_mode        -- �o�͋敪(=1�FPDF�o�́j
     ,iv_frm_file     => cv_svf_form_name      -- �t�H�[���l���t�@�C����
     ,iv_vrq_file     => cv_svf_query_name     -- �N�G���[�l���t�@�C����
     ,iv_org_id       => fnd_global.org_id     -- ORG_ID
     ,iv_user_name    => lv_user_name          -- ���O�C���E���[�U��
     ,iv_resp_name    => lv_resp_name          -- ���O�C���E���[�U�̐E�Ӗ�
     ,iv_doc_name     => NULL                  -- ������
     ,iv_printer_name => NULL                  -- �v�����^��
     ,iv_request_id   => cn_request_id         -- �v��ID
     ,iv_nodata_msg   => NULL                  -- �f�[�^�Ȃ����b�Z�[�W
     );
--
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_06        --���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_api_nm           --�g�[�N���R�[�h1
                 ,iv_token_value1 => cv_tkn_api_nm_svf       --�g�[�N���l1
                );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
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
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END act_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_row
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-8)
   ***********************************************************************************/
  PROCEDURE delete_row(
     ov_errbuf              OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'delete_row';     -- �v���O������
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
    cv_tkn_tbl_nm         CONSTANT VARCHAR2(100) := '���K��ڋq�ꗗ�\���[���[�N�e�[�u��';
    -- *** ���[�J���ϐ� ***
    lt_line_num           xxcso_rep_novisit.line_num%TYPE;  -- ���K��ڋq�ꗗ�\���[���[�N�e�[�u���h�c�i�[�p
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==========================
    -- ���[�N�e�[�u���f�[�^�폜
    -- ==========================
    DELETE FROM xxcso_rep_novisit xrn -- ���K��ڋq�ꗗ�\���[���[�N�e�[�u��
    WHERE xrn.request_id = cn_request_id;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_row;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     iv_current_date     IN  VARCHAR2          --   ���
    ,ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
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
    cb_true                CONSTANT BOOLEAN := TRUE;
    cv_tkn_nvt_info        CONSTANT VARCHAR2(100) := '���K��ڋq�ꗗ���';
    cv_zero                CONSTANT VARCHAR2(5)   := '0';
    cv_accnt_type1         CONSTANT VARCHAR2(5)   := '10'; -- �ڋq�敪�i�ڋq�j
    cv_accnt_type2         CONSTANT VARCHAR2(5)   := '15'; -- �ڋq�敪�i����j
    cv_accnt_sts1          CONSTANT VARCHAR2(5)   := '25'; -- �ڋq�X�e�[�^�X�iSP���ύρj
    cv_accnt_sts2          CONSTANT VARCHAR2(5)   := '30'; -- �ڋq�X�e�[�^�X�i���F�ς݁j
    cv_accnt_sts3          CONSTANT VARCHAR2(5)   := '40'; -- �ڋq�X�e�[�^�X�i�ڋq�j
    cv_accnt_sts4          CONSTANT VARCHAR2(5)   := '50'; -- �ڋq�X�e�[�^�X�i�x�~�j
    cv_accnt_sts5          CONSTANT VARCHAR2(5)   := '99'; -- �ڋq�X�e�[�^�X�i�ΏۊO�j
    cv_target_div          CONSTANT VARCHAR2(5)   := '1';  -- �K��Ώ�
    -- OUT�p�����[�^�i�[�p
    ld_current_date        DATE;                     -- ���
    ld_first_date          DATE;                     -- ����̌���
    lv_employee_number     VARCHAR(30);              -- �]�ƈ��ԍ�
    lv_employee_name       VARCHAR(40);              -- ��������
    lv_work_base_code      VARCHAR2(150);            -- �Ζ��n���_�R�[�h
    lv_hub_name            VARCHAR2(4000);           -- �Ζ��n���_��
    lv_emp_chk_cd          VARCHAR2(5);              -- �c�ƈ��`�F�b�N�l
    ln_emp_cnt             NUMBER(10);               -- ����
    -- *** ���[�J���ϐ� ***
    lv_current_sts         VARCHAR2(100);            -- �ڋq�X�e�[�^�X�i�\�[�g�p�j
    ln_ins_cnt             NUMBER DEFAULT 0;         -- �J�E���^
    ln_line_num            NUMBER DEFAULT 0;         -- �s�ԍ�
    -- SVF�N��API�߂�l�i�[�p
    lv_errbuf_svf          VARCHAR2(5000);           -- �G���[�E���b�Z�[�W
    lv_retcode_svf         VARCHAR2(1);              -- ���^�[���E�R�[�h
    lv_errmsg_svf          VARCHAR2(5000);           -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �c�ƈ��ʖ��K��ڋq�f�[�^���o�J�[�\��
    CURSOR get_novisit_data_cur(
               iv_wb_cd      IN VARCHAR2  -- ���_�R�[�h
              ,iv_emp_num    IN VARCHAR2  -- �]�ƈ��R�[�h
              ,id_frt_dt     IN DATE      -- ����̌���
              ,id_crnt_dt    IN DATE      -- ���
              ,iv_emp_chk_cd IN VARCHAR2  -- �c�ƈ��`�F�b�N�l
            )
    IS
      SELECT  xrv.employee_number         employee_number       -- �]�ƈ��ԍ�
             ,SUBSTRB(xrv.last_name || xrv.first_name, 1, 40)   employee_name         -- ��������
             ,CASE
                WHEN  xcav.customer_status <= cv_accnt_sts2 THEN
                  xcav.customer_status
                ELSE
                  xcrv.route_number
              END                         route_customer       -- ���[�gNO/�ڋq�X�e�[�^�X
             ,xcav.account_number         account_number       -- �ڋq�R�[�h
             ,xcav.party_name             party_name           -- �ڋq��
             ,xcav.final_tran_date        final_tran_date      -- �ŏI�����
             ,xcav.final_call_date        final_call_date      -- �ŏI�K���
             ,xcav.business_low_type      business_low_type    -- �Ƒԁi�����ށj
             ,CASE
                WHEN  xcav.customer_status <= cv_accnt_sts2 THEN
                  2
                ELSE
                  1
              END                         status_sort          -- �ڋq�X�e�[�^�X�i�\�[�g�p�j
      FROM    xxcso_resources_v2      xrv                      -- ���\�[�X�}�X�^(�ŐV)VIEW
             ,xxcso_cust_accounts_v   xcav                     -- �ڋq�}�X�^VIEW
             ,xxcso_cust_routes_v2    xcrv                     -- �ڋq���[�gNo�i�ŐV�jVIEW
             ,xxcso_cust_resources_v2 xcrev                    -- �c�ƈ��S���ڋq�i�ŐV�jVIEW
             ,(
                SELECT employee_number
                      ,xxcso_util_common_pkg.get_emp_parameter(
                         xrv2.work_base_code_new
                        ,xrv2.work_base_code_old
                        ,xrv2.issue_date
                        ,TRUNC(xxcso_util_common_pkg.get_online_sysdate)) work_base_code
                FROM xxcso_resources_v2 xrv2
              ) xrv3
      WHERE   xrv3.work_base_code   = iv_wb_cd
        AND   (
                xcav.final_call_date < id_frt_dt
                OR
                xcav.final_call_date > id_crnt_dt
                OR
                xcav.final_call_date IS NULL
              )
        AND ((xcav.customer_class_code = cv_accnt_type1
               AND xcav.customer_status IN (cv_accnt_sts1, cv_accnt_sts2,
                                             cv_accnt_sts3, cv_accnt_sts4)
              )
            OR (xcav.customer_class_code = cv_accnt_type2
               AND xcav.customer_status = cv_accnt_sts5
              ))
        AND   xcav.vist_target_div = cv_target_div
        AND ((iv_emp_chk_cd  =  cv_true
               AND xrv.employee_number   = iv_emp_num
              )
            OR (iv_emp_chk_cd   =  cv_false
               AND 1 = 1
              ))
        AND   xrv3.employee_number  = xrv.employee_number
        AND   xcrev.employee_number = xrv.employee_number
        AND   xcrev.account_number  = xcav.account_number
        AND   xcav.account_number   = xcrv.account_number(+)
      ;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �c�ƈ��ʌ������o�J�[�\��
    CURSOR get_emp_cnt_cur
    IS
      SELECT  xrn.employee_number         employee_number       -- �]�ƈ��ԍ�
             ,COUNT(xrn.employee_number)  emp_cnt               -- ����
      FROM    xxcso_rep_novisit   xrn
      WHERE   xrn.request_id = cn_request_id
        AND   xrn.mc_flag    = cv_zero
      GROUP BY xrn.employee_number
      ;

    -- *** ���[�J���E���R�[�h ***
    l_get_novisit_dt_rec     get_novisit_data_cur%ROWTYPE;
    l_rp_nov_dt_rec          g_rp_nov_data_rtype;
    l_get_emp_cnt_rec        get_emp_cnt_cur%ROWTYPE;
    -- *** ���[�J���E��O ***
    no_data_expt           EXCEPTION; -- �Ώۃf�[�^0����O
    -- ���b�Z�[�W�i�[�p
    lv_msg                   VARCHAR2(5000);
    -- �x�����b�Z�[�W�o�͔��f�t���O
    lv_msg_flg               BOOLEAN DEFAULT FALSE;
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
    -- �J�E���^�̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    ln_ins_cnt    := 0;
--
    -- ========================================
    -- A-1.��������
    -- ========================================
    init(
      iv_current_date    => iv_current_date     -- ���
     ,ov_employee_number => lv_employee_number  -- �]�ƈ��R�[�h
     ,ov_employee_name   => lv_employee_name    -- ��������
     ,ov_work_base_code  => lv_work_base_code   -- �Ζ��n���_�R�[�h
     ,ov_hub_name        => lv_hub_name         -- �Ζ��n���_��
     ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ========================================
    -- A-2.�p�����[�^�`�F�b�N
    -- ========================================
    chk_param(
       iv_current_date     => iv_current_date        -- ���
      ,od_current_date     => ld_current_date        -- ���(DATE�^)
      ,od_first_date       => ld_first_date          -- ����̌���(DATE�^)
      ,ov_emp_chk_cd       => lv_emp_chk_cd          -- �c�ƈ��`�F�b�N�l
      ,ov_errbuf           => lv_errbuf              -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode          => lv_retcode             -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg           => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ========================================
    -- A-3.�f�[�^�擾
    -- ========================================
    -- �J�[�\���I�[�v��
    OPEN get_novisit_data_cur(
               iv_wb_cd      => lv_work_base_code  -- ���_�R�[�h
              ,iv_emp_num    => lv_employee_number -- �]�ƈ��R�[�h
              ,id_frt_dt     => ld_first_date      -- ����̌���
              ,id_crnt_dt    => ld_current_date    -- ���
              ,iv_emp_chk_cd => lv_emp_chk_cd      -- �c�ƈ��`�F�b�N�l
            );
--
    <<get_novisit_data_loop>>
    LOOP
      FETCH get_novisit_data_cur INTO l_get_novisit_dt_rec;
      -- �����Ώی����i�[
      gn_target_cnt := get_novisit_data_cur%ROWCOUNT;
--
      -- �����Ώۃf�[�^�����݂��Ȃ������ꍇEXIT
      EXIT WHEN get_novisit_data_cur%NOTFOUND
      OR  get_novisit_data_cur%ROWCOUNT = 0;
--
      -- ���R�[�h�ϐ�������
      l_rp_nov_dt_rec := NULL;
--
      -- �s�ԍ����擾
      ln_line_num := ln_line_num + 1;
--
      -- �擾�f�[�^���i�[
      l_rp_nov_dt_rec.line_num                   := ln_line_num;                             -- �s�ԍ�
      l_rp_nov_dt_rec.base_date                  := ld_current_date;                         -- ��N����
      l_rp_nov_dt_rec.base_date_start            := ld_first_date;                           -- ���START
      l_rp_nov_dt_rec.base_date_end              := ld_current_date;                         -- ���END
      l_rp_nov_dt_rec.base_code                  := lv_work_base_code;                       -- ���_�R�[�h
      l_rp_nov_dt_rec.hub_name                   := lv_hub_name;                             -- ���_����
      l_rp_nov_dt_rec.employee_number            := l_get_novisit_dt_rec.employee_number;    -- �]�ƈ��ԍ�
      l_rp_nov_dt_rec.employee_name              := l_get_novisit_dt_rec.employee_name;      -- ��������
      l_rp_nov_dt_rec.route_no                   := l_get_novisit_dt_rec.route_customer;     -- ���[�gNO/�ڋq�X�e�[�^�X
      l_rp_nov_dt_rec.account_number             := l_get_novisit_dt_rec.account_number;     -- �ڋq�R�[�h
      l_rp_nov_dt_rec.account_name               := l_get_novisit_dt_rec.party_name;         -- �ڋq��
      l_rp_nov_dt_rec.final_tran_date            := l_get_novisit_dt_rec.final_tran_date;    -- �ŏI�����
      l_rp_nov_dt_rec.final_call_date            := l_get_novisit_dt_rec.final_call_date;    -- �ŏI�K���
      l_rp_nov_dt_rec.business_low_type          := l_get_novisit_dt_rec.business_low_type;  -- �Ƒԁi�����ށj
      l_rp_nov_dt_rec.created_by                 := cn_created_by;                           -- �쐬��
      l_rp_nov_dt_rec.creation_date              := cd_creation_date;                        -- �쐬��
      l_rp_nov_dt_rec.last_updated_by            := cn_last_updated_by;                      -- �ŏI�X�V��
      l_rp_nov_dt_rec.last_update_date           := cd_last_update_date;                     -- �ŏI�X�V��
      l_rp_nov_dt_rec.last_update_login          := cn_last_update_login;                    -- �ŏI�X�V���O�C��
      l_rp_nov_dt_rec.request_id                 := cn_request_id;                           -- �v���h�c
      l_rp_nov_dt_rec.program_application_id     := cn_program_application_id;               -- �ݶ�����۸��ѱ��ع����
      l_rp_nov_dt_rec.program_id                 := cn_program_id;                           -- �ݶ�����۸��тh�c
      l_rp_nov_dt_rec.program_update_date        := cd_program_update_date;                  -- ��۸��эX�V��
      lv_current_sts                             := l_get_novisit_dt_rec.status_sort;         -- �ڋq�X�e�[�^�X�i�\�[�g�p�j
--
      -- ========================================
      -- A-4.���H����
      -- ========================================
      process_data(
        io_rp_nov_dt_rec       => l_rp_nov_dt_rec        -- ���K��ڋq�f�[�^
       ,iv_account_sts         => lv_current_sts         -- �ڋq�X�e�[�^�X�i�\�[�g�p�j
       ,ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W            --# �Œ� #
       ,ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h              --# �Œ� #
       ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      -- ========================================
      -- A-5.���[�N�e�[�u���o��
      -- ========================================
      insert_row(
        i_rp_nov_dt_rec        => l_rp_nov_dt_rec        -- ���K��ڋq�f�[�^
       ,ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W            --# �Œ� #
       ,ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h              --# �Œ� #
       ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- INSERT�����������J�E���g�A�b�v
      ln_ins_cnt := ln_ins_cnt + 1;
--
    END LOOP get_novisit_data_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE get_novisit_data_cur;
--
    -- �����Ώۃf�[�^��0���̏ꍇ
    IF (gn_target_cnt = 0) THEN
      -- 0�����b�Z�[�W�o��
      lv_msg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_tkn_number_07    --���b�Z�[�W�R�[�h
                );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_msg                                 --���[�U�[�E�G���[���b�Z�[�W
      );
--
      ov_retcode := cv_status_normal;
    ELSE
      -- �J�[�\���I�[�v��
      OPEN get_emp_cnt_cur;
--
      <<get_emp_cnt_loop>>
      LOOP
        FETCH get_emp_cnt_cur INTO l_get_emp_cnt_rec;
--
        -- �����Ώۃf�[�^�����݂��Ȃ������ꍇEXIT
        EXIT WHEN get_emp_cnt_cur%NOTFOUND
        OR  get_emp_cnt_cur%ROWCOUNT = 0;
      -- ========================================
      -- A-6.���[�N�e�[�u���X�V
      -- ========================================
        update_row(
          iv_employee_number     => l_get_emp_cnt_rec.employee_number        -- �]�ƈ��ԍ�
         ,in_emp_cnt             => l_get_emp_cnt_rec.emp_cnt                -- ����
         ,ov_errbuf              => lv_errbuf                                -- �G���[�E���b�Z�[�W            --# �Œ� #
         ,ov_retcode             => lv_retcode                               -- ���^�[���E�R�[�h              --# �Œ� #
         ,ov_errmsg              => lv_errmsg                                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END LOOP get_emp_cnt_loop;
--
      -- �J�[�\���N���[�Y
      CLOSE get_emp_cnt_cur;
--
      -- ========================================
      -- A-7.SVF�N��
      -- ========================================
      act_svf(
         ov_errbuf     => lv_errbuf_svf                        -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode    => lv_retcode_svf                       -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg     => lv_errmsg_svf                        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
      IF  (lv_retcode_svf <> cv_status_error) THEN
        gn_normal_cnt := ln_ins_cnt;
      END IF;
--
    END IF;
--
    -- ========================================
    -- A-8.���[�N�e�[�u���f�[�^�폜
    -- ========================================
    delete_row(
       ov_errbuf     => lv_errbuf                        -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode    => lv_retcode                       -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg     => lv_errmsg                        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-9.SVF�N��API�G���[�`�F�b�N
    -- ========================================
    IF (lv_retcode_svf = cv_status_error) THEN
      lv_errmsg := lv_errmsg_svf;
      lv_errbuf := lv_errbuf_svf;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_novisit_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_novisit_data_cur;
      END IF;
--
      IF (get_emp_cnt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_emp_cnt_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_novisit_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_novisit_data_cur;
      END IF;
--
      IF (get_emp_cnt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_emp_cnt_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_novisit_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_novisit_data_cur;
      END IF;
--
      IF (get_emp_cnt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_emp_cnt_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
     errbuf             OUT NOCOPY VARCHAR2    --   �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode            OUT NOCOPY VARCHAR2    --   ���^�[���E�R�[�h    --# �Œ� #
    ,iv_current_date    IN  VARCHAR2           --   ���
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
--
    /* 2009.05.20 M.Ohtsuki T1_0696�Ή� START */
--    cv_log_msg         CONSTANT VARCHAR2(100) := '�V�X�e���G���[���������܂����B�V�X�e���Ǘ��҂Ɋm�F���Ă��������B';
    /* 2009.05.20 M.Ohtsuki T1_0696�Ή� END */
    -- �G���[���b�Z�[�W
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_log             CONSTANT VARCHAR2(3)   := 'LOG';  -- �R���J�����g�w�b�_���b�Z�[�W�o�� �o�͋敪
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
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
       iv_current_date => iv_current_date    -- ���
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg       => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
       fnd_file.put_line(
          which  => FND_FILE.LOG
    /* 2009.05.20 M.Ohtsuki T1_0696�Ή� START */
--         ,buff   => lv_errmsg                  --���[�U�[�E�G���[���b�Z�[�W
--��������������������������������������������������������������������������������������������������
         ,buff   => SUBSTRB(
                    cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf ,1,5000
                    )
    /* 2009.05.20 M.Ohtsuki T1_0696�Ή� END */
       );
    /* 2009.05.20 M.Ohtsuki T1_0696�Ή� START */
--       fnd_file.put_line(
--          which  => FND_FILE.LOG
--         ,buff   => SUBSTRB(
--                      cv_log_msg ||cv_msg_prnthss_l||
--                      cv_pkg_name||cv_msg_cont||
--                      cv_prg_name||cv_msg_part||
--                      lv_errbuf  ||cv_msg_prnthss_r,1,5000
--                    )
--       );                                                     --�G���[���b�Z�[�W
    /* 2009.05.20 M.Ohtsuki T1_0696�Ή� START */
    END IF;
--
    -- =======================
    -- A-10.�I������ 
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;      
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
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
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
END XXCSO019A08C;
/
