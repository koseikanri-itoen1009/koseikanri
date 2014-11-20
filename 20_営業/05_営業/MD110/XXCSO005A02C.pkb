CREATE OR REPLACE PACKAGE BODY APPS.XXCSO005A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO005A02C(body)
 * Description      : �c�ƈ����\�[�X�`�F�b�NCSV�o��
 * MD.050           : �c�ƈ����\�[�X�`�F�b�NCSV�o�� (MD050_CSO_005A02)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_resource_data      �c�ƈ����\�[�X���擾(A-2)
 *  output_data            CSV�t�@�C���o��(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2013/10/10    1.0   S.Niki           �V�K�쐬
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
  global_warn_expt          EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCSO005A02C';      -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxcso    CONSTANT VARCHAR2(10)  := 'XXCSO';             -- XXCSO
  -- ���t����
  cv_fmt_yyyymmdd       CONSTANT VARCHAR2(50)  := 'YYYY/MM/DD';
  -- ��������
  cv_dqu                CONSTANT VARCHAR2(1)   := '"';                 -- �����񊇂�
  cv_comma              CONSTANT VARCHAR2(1)   := ',';                 -- �J���}
  -- ���b�Z�[�W�R�[�h
  cv_msg_cso_00130      CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00130';  -- ���_�R�[�h
  cv_msg_cso_00129      CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00129';  -- ��N����
  cv_msg_cso_00224      CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00224';  -- CSV�t�@�C���o��0���G���[
  cv_msg_cso_00656      CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00656';  -- �c�ƈ����\�[�XCSV�w�b�_
--
  -- �g�[�N��
  cv_tkn_entry          CONSTANT VARCHAR2(20)  := 'ENTRY';             -- ���͒l
  cv_tkn_count          CONSTANT VARCHAR2(20)  := 'COUNT';             -- ����
--
  cv_yes                CONSTANT VARCHAR2(1)                          := 'Y';                -- YES
  cv_no                 CONSTANT VARCHAR2(1)                          := 'N';                -- NO
  ct_ctg_emp            jtf_rs_resource_extns_vl.category%TYPE        := 'EMPLOYEE';         -- �J�e�S���[
  ct_res_grm            jtf_rs_defresroles_vl.role_resource_type%TYPE := 'RS_GROUP_MEMBER';  -- RS_GROUP_MEMBER
  ct_res_idv            jtf_rs_role_relations.role_resource_type%TYPE := 'RS_INDIVIDUAL';    -- RS_INDIVIDUAL
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_base_code          jtf_rs_groups_vl.attribute1%TYPE;  -- �p�����[�^���_�R�[�h
  gd_base_date          DATE;                              -- �p�����[�^��N����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���E�J�[�\��
  -- ===============================
  CURSOR resorce_data_cur
  IS
    SELECT  r.resource_id                                     AS resource_id       -- ���\�[�XID
           ,r.source_number                                   AS source_number     -- �]�ƈ��ԍ�
           ,r.source_name                                     AS source_name       -- �]�ƈ�����
           ,r.attribute1                                      AS emp_form          -- �c�ƌ`��(DFF1)
           ,r.attribute2                                      AS renraku           -- �A����(DFF2)
           ,r.attribute3                                      AS vd_toitu          -- VD����L�[NO(DFF3)
           ,r.attribute4                                      AS emp_dash          -- �c�ƃ_�b�V���{�[�h�g�p�\�t���O(DFF4)
           ,g.attribute1                                      AS base_code         -- ���_�R�[�h(DFF1)
           ,g.group_name                                      AS group_name        -- �O���[�v����(���_��)
           ,rol.role_name                                     AS rol_name          -- �O���[�v�����o��������
           ,TO_CHAR(rol.res_rl_start_date ,cv_fmt_yyyymmdd)   AS rol_start_date    -- �O���[�v�����o�����J�n��
           ,TO_CHAR(rol.res_rl_end_date   ,cv_fmt_yyyymmdd)   AS rol_end_date      -- �O���[�v�����o�����I����
           ,m.attribute1                                      AS group_leader      -- �O���[�v���敪(DFF1)
           ,m.attribute2                                      AS group_num         -- �O���[�v�ԍ�(DFF2)
           ,m.attribute3                                      AS group_order       -- �O���[�v����(DFF3)
    FROM    jtf_rs_resource_extns_vl  r    -- ���\�[�X
           ,jtf_rs_group_members      m    -- ���\�[�X�O���[�v�����o�[
           ,jtf_rs_groups_vl          g    -- ���\�[�X�O���[�v
           ,jtf_rs_defresroles_vl     rol  -- �O���[�v�����o����
    WHERE   r.category                      = ct_ctg_emp             -- �J�e�S��'EMPLOYEE'
    AND     r.resource_id                   = m.resource_id
    AND     NVL(m.delete_flag(+) ,cv_no)    <> cv_yes
    AND     m.group_id                      = g.group_id
    AND     m.group_member_id               = rol.role_resource_id(+)
    AND     rol.role_resource_type(+)       = ct_res_grm             -- 'RS_GROUP_MEMBER'
    AND     NVL(rol.delete_flag(+) ,cv_no)  <> cv_yes
    AND     g.attribute1                    = gt_base_code           -- �p�����[�^.���_�R�[�h
    AND    (
              ( gd_base_date       BETWEEN  r.start_date_active    -- �p�����[�^.��N�����i���\�[�X�j
                                   AND      NVL(r.end_date_active, gd_base_date) )
            OR
              ( gd_base_date                < r.start_date_active )
           )
    AND    (
              ( gd_base_date       BETWEEN  rol.res_rl_start_date  -- �p�����[�^.��N�����i���\�[�X�����j
                                   AND      NVL(rol.res_rl_end_date, gd_base_date) )
            OR
              ( gd_base_date                < rol.res_rl_start_date )
            OR
              ( rol.res_rl_start_date       IS NULL )
           )
    ORDER BY
            r.source_number          -- �]�ƈ��ԍ�
           ,rol.res_rl_start_date    -- �O���[�v�����o�����J�n��
    ;
--
  --�擾�f�[�^�i�[�ϐ���`
  TYPE g_out_file_ttype IS TABLE OF resorce_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_out_file_tab       g_out_file_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code  IN  VARCHAR2,     -- 1.���_�R�[�h
    iv_base_date  IN  VARCHAR2,     -- 2.��N����
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
    lv_msg_base_code        VARCHAR2(1000);  -- ���_�R�[�h�o�͗p
    lv_msg_base_date        VARCHAR2(1000);  -- ��N�����o�͗p
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==================================================
    -- ���̓p�����[�^�i�[
    --==================================================
    gt_base_code := iv_base_code;
    gd_base_date := TO_DATE(iv_base_date ,cv_fmt_yyyymmdd);
--
    -- ���_�R�[�h
    lv_msg_base_code   := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_msg_cso_00130              -- ���b�Z�[�W�R�[�h
                          , iv_token_name1  => cv_tkn_entry                  -- �g�[�N���R�[�h1
                          , iv_token_value1 => iv_base_code                  -- �g�[�N���l1
                          );
    -- ��N����
    lv_msg_base_date   := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_msg_cso_00129              -- ���b�Z�[�W�R�[�h
                          , iv_token_name1  => cv_tkn_entry                  -- �g�[�N���R�[�h1
                          , iv_token_value1 => iv_base_date                  -- �g�[�N���l1
                          );
--
    -- ���O�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''               || CHR(10) ||
                 lv_msg_base_code || CHR(10) ||   -- ���_�R�[�h
                 lv_msg_base_date || CHR(10)      -- ��N����
    );
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : get_resource_data
   * Description      : �c�ƈ����\�[�X���擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_resource_data(
    ov_errbuf                       OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_resource_data'; -- �v���O������
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
    --�Ώۃf�[�^�擾
    OPEN  resorce_data_cur;
    FETCH resorce_data_cur BULK COLLECT INTO gt_out_file_tab;
    CLOSE resorce_data_cur;
--
    --���������J�E���g
    gn_target_cnt := gt_out_file_tab.COUNT;
--
    IF ( gn_target_cnt = 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END get_resource_data;
--
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : CSV�t�@�C���o��(A-3)
   ***********************************************************************************/
  PROCEDURE output_data(
    ov_errbuf                       OUT    VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- �v���O������
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
    lv_line_data            VARCHAR2(5000);         -- OUTPUT�f�[�^�ҏW�p
    lv_out_process_time     VARCHAR2(10);           -- �ҏW��̏�������
    lv_csv_header           VARCHAR2(5000);         -- CSV�w�b�_�o�͗p
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    TYPE g_head_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
    -- *** ���[�J���E�e�[�u�� ***
    lt_head_tab g_head_ttype;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ----------------------
    --CSV�w�b�_�o��
    ----------------------
    lv_csv_header := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcso
                    ,iv_name         => cv_msg_cso_00656
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_header
    );
--
    ----------------------
    --�f�[�^�o��
    ----------------------
    --�f�[�^���擾
    <<data_output>>
    FOR i IN 1..gt_out_file_tab.COUNT LOOP
      --������
      lv_line_data := NULL;
      --�f�[�^��ҏW
      lv_line_data :=                cv_dqu || gt_out_file_tab(i).resource_id     || cv_dqu  -- ���\�[�XID
                      || cv_comma || cv_dqu || gt_out_file_tab(i).source_number   || cv_dqu  -- �]�ƈ��ԍ�
                      || cv_comma || cv_dqu || gt_out_file_tab(i).source_name     || cv_dqu  -- �]�ƈ�����
                      || cv_comma || cv_dqu || gt_out_file_tab(i).emp_form        || cv_dqu  -- �c�ƌ`��
                      || cv_comma || cv_dqu || gt_out_file_tab(i).renraku         || cv_dqu  -- �A����
                      || cv_comma || cv_dqu || gt_out_file_tab(i).vd_toitu        || cv_dqu  -- VD����L�[NO
                      || cv_comma || cv_dqu || gt_out_file_tab(i).emp_dash        || cv_dqu  -- �c�ƃ_�b�V���{�[�h�g�p�\�t���O
                      || cv_comma || cv_dqu || gt_out_file_tab(i).base_code       || cv_dqu  -- ���_�R�[�h
                      || cv_comma || cv_dqu || gt_out_file_tab(i).group_name      || cv_dqu  -- �O���[�v���́i���_���j
                      || cv_comma || cv_dqu || gt_out_file_tab(i).rol_name        || cv_dqu  -- �O���[�v��������
                      || cv_comma || cv_dqu || gt_out_file_tab(i).rol_start_date  || cv_dqu  -- �O���[�v�����o�����J�n��
                      || cv_comma || cv_dqu || gt_out_file_tab(i).rol_end_date    || cv_dqu  -- �O���[�v�����o�����I����
                      || cv_comma || cv_dqu || gt_out_file_tab(i).group_leader    || cv_dqu  -- �O���[�v���敪
                      || cv_comma || cv_dqu || gt_out_file_tab(i).group_num       || cv_dqu  -- �O���[�v�ԍ�
                      || cv_comma || cv_dqu || gt_out_file_tab(i).group_order     || cv_dqu  -- �O���[�v����
                      ;
      --�f�[�^���o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
--
      --���������J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP data_output;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code  IN  VARCHAR2,     -- 1.���_�R�[�h
    iv_base_date  IN  VARCHAR2,     -- 2.��N����
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
    -- ===============================
    -- ���[�J���E�J�[�\��
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
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      iv_base_code,      -- 1.���_�R�[�h
      iv_base_date,      -- 2.��N����
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �c�ƈ����\�[�X���擾(A-2)
    -- ===============================
    get_resource_data(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --�x������
      RAISE global_warn_expt;
    END IF;
    -- ===============================
    -- CSV�t�@�C���o��(A-3)
    -- ===============================
    output_data(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    --�f�[�^�Ȃ��x��
    WHEN global_warn_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := ov_errmsg;
      ov_retcode := lv_retcode;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_base_code  IN  VARCHAR2,      -- 1.���_�R�[�h
    iv_base_date  IN  VARCHAR2       -- 2.��N����
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
    cv_appl_name_xxccp CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O
--
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
       iv_which   => cv_log_header_log
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
       iv_base_code   -- ���_�R�[�h
      ,iv_base_date   -- ��N����
      ,lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================
    -- �I������(A-6)
    -- ===============================
    --�X�e�[�^�X����
    IF (lv_retcode = cv_status_warn) THEN
      --CSV�t�@�C���o��0���G���[
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcso
                      ,iv_name         => cv_msg_cso_00224
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
    ELSIF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;  --�Ώی���
      gn_normal_cnt := 0;  --��������
      gn_error_cnt  := 1;  --�G���[����
      --
      --�G���[�o��
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
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
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
                     iv_application  => cv_appl_name_xxccp
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
END XXCSO005A02C;
/