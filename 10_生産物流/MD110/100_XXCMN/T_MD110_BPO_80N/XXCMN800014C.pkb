CREATE OR REPLACE PACKAGE BODY XXCMN800014C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCMN800014C(body)
 * Description      : ���Y�o�b�`����CSV�t�@�C���o�͂��A���[�N�t���[�`���ŘA�g���܂��B
 * MD.050           : ���Y�o�b�`���C���^�t�F�[�X<T_MD050_BPO_801>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������                              (A-1)
 *  output_data            �f�[�^�擾�ECSV�o�͏���               (A-2)
 *  submain                 ���C�������v���V�[�W��
 *                         �I������                              (A-3)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/07/11    1.0   S.Yamashita      �V�K�쐬
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_sla                CONSTANT VARCHAR2(3) := '�^';
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
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCMN800014C';         -- �p�b�P�[�W��
  -- ���b�Z�[�W�֘A
  cv_app_xxcmn                CONSTANT VARCHAR2(30)  := 'XXCMN';                -- �A�v���P�[�V�����Z�k��(���Y:�}�X�^)
  cv_msg_xxcmn_11044          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11044';      -- ���Y�o�b�`���A�g�p�����[�^
  cv_msg_xxcmn_11047          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11047';      -- ���t�t�]�G���[
  cv_msg_xxcmn_11048          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11048';      -- �Ώۃf�[�^���擾�G���[
  cv_msg_xxcmn_11055          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11055';      -- EOS����擾�G���[
  -- �g�[�N���p���b�Z�[�W
  cv_msg_xxcmn_11045          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11045';      -- �����i������(FROM)
  cv_msg_xxcmn_11046          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11046';      -- �����i������(TO)
  --�g�[�N��
  cv_tkn_batch_no             CONSTANT VARCHAR2(20)  := 'BATCH_NO';             -- ���̓p�����[�^�i�o�b�`NO�j
  cv_tkn_whse_code            CONSTANT VARCHAR2(20)  := 'WHSE_CODE';            -- ���̓p�����[�^�i�q�ɃR�[�h�j
  cv_tkn_production_date_from CONSTANT VARCHAR2(20)  := 'PRODUCTION_DATE_FROM'; -- ���̓p�����[�^�i�����i������(FROM)�j
  cv_tkn_production_date_to   CONSTANT VARCHAR2(20)  := 'PRODUCTION_DATE_TO';   -- ���̓p�����[�^�i�����i������(TO)�j
  cv_tkn_p_routing            CONSTANT VARCHAR2(20)  := 'ROUTING';              -- ���̓p�����[�^�i���C��No�j
  cv_tkn_from                 CONSTANT VARCHAR2(20)  := 'FROM';                 -- ���t�iFROM�j
  cv_tkn_to                   CONSTANT VARCHAR2(20)  := 'TO';                   -- ���t�iTO�j
  cv_tkn_ng_profile           CONSTANT VARCHAR2(20)  := 'NG_PROFILE';           -- �v���t�@�C��
--
  -- ����R�[�h
  ct_lang               CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
  --�t�H�[�}�b�g
  cv_fmt_month          CONSTANT VARCHAR2(30)  := 'YYYYMM';
  cv_fmt_date           CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD';
  cv_fmt_datetime       CONSTANT VARCHAR2(30)  := 'YYYYMMDDHH24MISS';
  cv_fmt_datetime2      CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS';
  -- WF�֘A
  cv_ope_div_10         CONSTANT VARCHAR2(2)   := '10';  -- �����敪:10(���Y�o�b�`���)
  cv_wf_class_1         CONSTANT VARCHAR2(1)   := '1';   -- �Ώ�:1(�O���q��)
  cv_eos_flag_1         CONSTANT VARCHAR2(1)   := '1';   -- EOS�Ǘ��Ώ�:1(�Ώہj
  -- ���̑�
  cv_y                  CONSTANT VARCHAR2(1)   := 'Y';   -- �t���O:'Y'
  cv_space              CONSTANT VARCHAR2(1)   := ' ';   -- ���p�X�y�[�X�P��
  cv_separate_code      CONSTANT VARCHAR2(1)   := ',';   -- ��؂蕶���i�J���}�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  -- ===============================
  -- �J�[�\����`
  -- ===============================
  -- ���Y�o�b�`��񒊏o
  CURSOR g_batch_info_cur ( iv_p_batch_no       VARCHAR2 -- �o�b�`NO
                           ,iv_p_whse_code      VARCHAR2 -- �q�ɃR�[�h
                           ,iv_p_prod_date_from VARCHAR2 -- �����i������(FROM)
                           ,iv_p_prod_date_to   VARCHAR2 -- �����i������(TO)
                           ,iv_p_routing        VARCHAR2 -- ���C��No
                          )
  IS
    SELECT xsh.�o�b�`NO              AS batch_no
          ,xsh.�v�����g�R�[�h        AS plant_code
          ,xsh.�H��                  AS routing_no
          ,xsh.�Ɩ��X�e�[�^�X        AS business_status
          ,xsh.�v�抮����            AS plan_cmplt_date
          ,xsh.���ъ�����            AS actual_cmplt_date
          ,xsh.�폜�}�[�N            AS delete_mark
          ,xsh.�`�[�敪              AS invoice_type
          ,xsh.���ъǗ�����          AS result_manage_dept
          ,xsh.�����i_�i�ڃR�[�h     AS prod_item_no
          ,xsh.�����i_���b�gNO       AS prod_lot_no
          ,xsh.�����i_�^�C�v         AS prod_item_type
          ,xsh.�����i_�����N����     AS prod_producted_date
          ,xsh.�����i_�ŗL�L��       AS prod_uniqe_sign
          ,xsh.�����i_�ܖ�������     AS prod_use_by_date
          ,xsh.�����i_���Y��         AS prod_manufactured_date
          ,xsh.�����i_�������ɓ�     AS prod_material_stored_date
          ,xsh.�����i_���ѐ���       AS prod_actual_qty
          ,xsh.�����i_�P��           AS prod_item_um
          ,xsh.�����i_�����N�P       AS prod_rank1
          ,xsh.�����i_�����N�Q       AS prod_rank2
          ,xsh.�����i_�����N�R       AS prod_rank3
          ,xsh.�����i_�E�v           AS prod_discription
          ,xsh.�����i_�݌ɓ���       AS prod_in_qty
          ,xsh.�����i_�˗�����       AS prod_request_qty
          ,xsh.�����i_�w�}����       AS prod_instruct_qty
          ,xsh.�����i_�ړ��ꏊ�R�[�h AS prod_move_location
          ,TO_DATE( xsh.�ŏI�X�V��, cv_fmt_datetime2 ) AS h_last_update_date
          ,xsl.���C��NO              AS line_no
          ,xsl.�i�ڃR�[�h            AS item_no
          ,xsl.���b�gNO              AS lot_no
          ,xsl.�����N����            AS producted_date
          ,xsl.�ŗL�L��              AS uniqe_sign
          ,xsl.�ܖ�������            AS use_by_date
          ,xsl.���C���^�C�v          AS line_type
          ,xsl.�^�C�v                AS item_type
          ,xsl.�������敪            AS inlet_type
          ,xsl.�ō��敪              AS actual_qty
          ,xsl.���Y��                AS manufactured_date
          ,xsl.�������ɓ�            AS material_stored_date
          ,xsl.�P��                  AS item_um
          ,xsl.�����N�P              AS rank1
          ,xsl.�����N�Q              AS rank2
          ,xsl.�����N�R              AS rank3
          ,xsl.�E�v                  AS discription
          ,xsl.�݌ɓ���              AS in_qty
          ,xsl.�˗�����              AS request_qty
          ,xsl.�����폜�t���O        AS material_del_flag
          ,xsl.���b�g_�w������       AS lot_instruct_qty
          ,xsl.���b�g_��������       AS lot_input_qty
          ,xsl.���b�g_�\��敪       AS lot_plan_type
          ,xsl.���b�g_�\��ԍ�       AS lot_plan_num
          ,TO_DATE( xsl.�ŏI�X�V��, cv_fmt_datetime2 ) AS l_last_update_date
    FROM   xxsky_���Y�w�b�__��{_v xsh
          ,xxsky_���Y����_��{_v   xsl
          ,xxsky_�H���}�X�^_��{_v xkm
    WHERE  xsh.�H�� = xkm.�H���ԍ�
    AND    xsh.�o�b�`NO             = xsl.�o�b�`NO
    AND    xsh.�v�����g�R�[�h       = xsl.�v�����g�R�[�h
    AND    xkm.���Y�o�b�`���IF�Ώۃt���O = cv_y
    AND    ( (iv_p_batch_no IS NULL)  OR (xsh.�o�b�`NO = iv_p_batch_no) ) -- �o�b�`NO
    AND    xsh.WIP�q�� = iv_p_whse_code                                   -- �q�ɃR�[�h
    AND    NVL( TO_DATE( xsh.�����i_�����N����, cv_fmt_date ) , xsh.�v��J�n�� )
             >= TO_DATE( iv_p_prod_date_from, cv_fmt_date )               -- �����i������(FROM)
    AND    NVL( TO_DATE( xsh.�����i_�����N����, cv_fmt_date ) , xsh.�v��J�n�� )
             <= TO_DATE( iv_p_prod_date_to, cv_fmt_date )                 -- �����i������(TO)
    AND    ( (iv_p_routing IS NULL) OR (xsh.�H�� = iv_p_routing) )        -- ���C��No
    ORDER BY xsh.�o�b�`NO
            ,xsl.���C���^�C�v
            ,xsl.�i�ڃR�[�h
            ,xsl.���b�gNO
  ;
  -- ���R�[�h�^
  g_batch_info_rec  g_batch_info_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   **********************************************************************************/
  PROCEDURE init(
    iv_batch_no               IN  VARCHAR2  -- 1.�o�b�`NO
   ,iv_whse_code              IN  VARCHAR2  -- 2.�q�ɃR�[�h
   ,iv_production_date_from   IN  VARCHAR2  -- 3.�����i������(FROM)
   ,iv_production_date_to     IN  VARCHAR2  -- 4.�����i������(TO)
   ,iv_routing                IN  VARCHAR2  -- 5.���C��No
   ,ov_errbuf                 OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                 OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    lv_production_date_from VARCHAR2(100); -- �����i������(FROM)
    lv_production_date_to   VARCHAR2(100); -- �����i������(TO)
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==================================
    -- �p�����[�^�o��
    --==================================
    lv_errmsg := xxcmn_common_pkg.get_msg(
                   iv_application        => cv_app_xxcmn
                  ,iv_name               => cv_msg_xxcmn_11044
                  ,iv_token_name1        => cv_tkn_batch_no
                  ,iv_token_value1       => iv_batch_no
                  ,iv_token_name2        => cv_tkn_whse_code
                  ,iv_token_value2       => iv_whse_code
                  ,iv_token_name3        => cv_tkn_production_date_from
                  ,iv_token_value3       => iv_production_date_from
                  ,iv_token_name4        => cv_tkn_production_date_to
                  ,iv_token_value4       => iv_production_date_to
                  ,iv_token_name5        => cv_tkn_p_routing
                  ,iv_token_value5       => iv_routing
                 );
--
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => lv_errmsg
    );
    --1�s��
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => NULL
    );
--
    --==================================
    -- ���t�t�]�`�F�b�N
    --==================================
    IF ( TO_DATE( iv_production_date_from, cv_fmt_date ) > TO_DATE( iv_production_date_to, cv_fmt_date ) ) THEN
      -- �g�[�N���擾
      lv_production_date_from := xxcmn_common_pkg.get_msg(
                                   iv_application  => cv_app_xxcmn
                                  ,iv_name         => cv_msg_xxcmn_11045
                                 );
      lv_production_date_to   := xxcmn_common_pkg.get_msg(
                                   iv_application  => cv_app_xxcmn
                                  ,iv_name         => cv_msg_xxcmn_11046
                                 );
      -- ���t�t�]�`�F�b�N�G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_app_xxcmn
                    ,iv_name         => cv_msg_xxcmn_11047
                    ,iv_token_name1  => cv_tkn_from
                    ,iv_token_value1 => lv_production_date_from
                    ,iv_token_name2  => cv_tkn_to
                    ,iv_token_value2 => lv_production_date_to
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START  #######################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
   * Procedure Name   : output_data
   * Description      : CSV�o�͏��� (A-2)
   **********************************************************************************/
  PROCEDURE output_data(
    iv_batch_no               IN  VARCHAR2  -- 1.�o�b�`NO
   ,iv_whse_code              IN  VARCHAR2  -- 2.�q�ɃR�[�h
   ,iv_production_date_from   IN  VARCHAR2  -- 3.�����i������(FROM)
   ,iv_production_date_to     IN  VARCHAR2  -- 4.�����i������(TO)
   ,iv_routing                IN  VARCHAR2  -- 5.���C��No
   ,ov_errbuf                 OUT VARCHAR2  -- �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode                OUT VARCHAR2  -- ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg                 OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- �v���O������
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
    cv_data_type_700    CONSTANT VARCHAR2(3) := '700';   -- �f�[�^���:700(���Y�o�b�`���)
    cv_coop_name_itoen  CONSTANT VARCHAR2(5) := 'ITOEN'; -- ��Ж�:ITOEN
    cv_branch_no_10     CONSTANT VARCHAR2(2) := '10';    -- �`���p�}��:10(�w�b�_)
    cv_branch_no_20     CONSTANT VARCHAR2(2) := '20';    -- �`���p�}��:20(����)
--
    -- *** ���[�J���ϐ� ***
    lr_wf_whs_rec       xxwsh_common3_pkg.wf_whs_rec; -- �t�@�C�����i�[���R�[�h
    lf_file_hand        UTL_FILE.FILE_TYPE;           -- �t�@�C���E�n���h��
    lt_prev_batch_no    gme_batch_header.batch_no%TYPE;   -- �O���R�[�h�̃o�b�`NO
    lt_eos_dist         ic_whse_mst.orgn_code%TYPE;       -- EOS����
    lv_file_name        VARCHAR2(150);  -- �t�@�C����
    lv_csv_data         VARCHAR2(4000); -- CSV������
    ln_cnt              NUMBER;         -- �Ώی���
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
    -- �ϐ�������
    lv_csv_data        := NULL;
    lt_prev_batch_no   := NULL;
    lt_eos_dist        := NULL;
--
    -- ������擾
    BEGIN
      SELECT xilv.eos_detination AS eos_detination -- EOS����
      INTO   lt_eos_dist
      FROM   xxcmn_item_locations_v xilv  -- OPM�ۊǏꏊ���VIEW
      WHERE  xilv.whse_code        = iv_whse_code  -- �q�ɃR�[�h
      AND    xilv.eos_control_type = cv_eos_flag_1 -- EOS�Ǘ��Ώ�
      AND    ROWNUM = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- EOS����擾�G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_app_xxcmn
                      ,iv_name         => cv_msg_xxcmn_11055
                      ,iv_token_name1  => cv_tkn_whse_code
                      ,iv_token_value1 => iv_whse_code
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ���ʊ֐��u�A�E�g�o�E���h�����擾�֐��v�ďo
    xxwsh_common3_pkg.get_wsh_wf_info(
      iv_wf_ope_div       => cv_ope_div_10  -- �����敪
     ,iv_wf_class         => cv_wf_class_1  -- �Ώ�
     ,iv_wf_notification  => lt_eos_dist    -- ����
     ,or_wf_whs_rec       => lr_wf_whs_rec  -- �t�@�C�����
     ,ov_errbuf           => lv_errbuf      -- �G���[�E���b�Z�[�W
     ,ov_retcode          => lv_retcode     -- ���^�[���E�R�[�h
     ,ov_errmsg           => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �t�@�C�����ҏW
    --==================================
    lv_file_name := cv_ope_div_10                                          -- �����敪
                    || '-' || lt_eos_dist                                  -- ����
                    || '_' || TO_CHAR( SYSDATE, cv_fmt_datetime )          -- ��������
                    || lr_wf_whs_rec.file_name                             -- �t�@�C����
    ;
--
    -- WF�I�[�i�[���N�����[�U�֕ύX
    lr_wf_whs_rec.wf_owner := fnd_global.user_name;
--
    --==================================
    -- �t�@�C���I�[�v��
    --==================================
    lf_file_hand := UTL_FILE.FOPEN( lr_wf_whs_rec.directory -- �f�B���N�g��
                                   ,lv_file_name            -- �t�@�C����
                                   ,'w' )                   -- ���[�h�i�㏑�j
    ;
--
    --==================================
    -- ���Y�o�b�`��񒊏o
    --==================================
    <<batch_info_loop>>
    FOR g_batch_info_rec IN g_batch_info_cur ( iv_p_batch_no       => iv_batch_no             -- �o�b�`NO
                                              ,iv_p_whse_code      => iv_whse_code            -- �q�ɃR�[�h
                                              ,iv_p_prod_date_from => iv_production_date_from -- �����i������(FROM)
                                              ,iv_p_prod_date_to   => iv_production_date_to   -- �����i������(TO)
                                              ,iv_p_routing        => iv_routing              -- ���C��No
                                             )
    LOOP
      -- �I������
      EXIT batch_info_loop WHEN g_batch_info_cur%NOTFOUND;
--
      --==================================
      -- ���Y�o�b�`��� CSV�o��
      --==================================
--
      -- 1���R�[�h�ڂ̏ꍇ�A�܂��́A�O���R�[�h�ƃo�b�`NO���قȂ�ꍇ
      IF ( ( lt_prev_batch_no IS NULL )
        OR ( g_batch_info_rec.batch_no <> lt_prev_batch_no ))
      THEN
        -- �w�b�_�s
        lv_csv_data :=                     cv_coop_name_itoen                         -- ��Ж�
                    || cv_separate_code || cv_data_type_700                           -- �f�[�^���
                    || cv_separate_code || cv_branch_no_10                            -- �`���p�}��
                    || cv_separate_code || g_batch_info_rec.batch_no                  -- �o�b�`NO
                    || cv_separate_code || g_batch_info_rec.plant_code                -- �v�����g�R�[�h
                    || cv_separate_code || g_batch_info_rec.routing_no                -- �H��
                    || cv_separate_code || g_batch_info_rec.business_status           -- �Ɩ��X�e�[�^�X
                    || cv_separate_code || TO_CHAR(g_batch_info_rec.plan_cmplt_date  , cv_fmt_date) -- �v�抮����
                    || cv_separate_code || TO_CHAR(g_batch_info_rec.actual_cmplt_date, cv_fmt_date) -- ���ъ�����
                    || cv_separate_code || g_batch_info_rec.delete_mark               -- �폜�}�[�N
                    || cv_separate_code || g_batch_info_rec.invoice_type              -- �`�[�敪
                    || cv_separate_code || g_batch_info_rec.result_manage_dept        -- ���ъǗ�����
                    || cv_separate_code || g_batch_info_rec.prod_item_no              -- �����i_�i�ڃR�[�h
                    || cv_separate_code || g_batch_info_rec.prod_lot_no               -- �����i_���b�gNO
                    || cv_separate_code || g_batch_info_rec.prod_item_type            -- �����i_�^�C�v
                    || cv_separate_code || g_batch_info_rec.prod_producted_date       -- �����i_�����N����
                    || cv_separate_code || g_batch_info_rec.prod_uniqe_sign           -- �����i_�ŗL�L��
                    || cv_separate_code || g_batch_info_rec.prod_use_by_date          -- �����i_�ܖ�������
                    || cv_separate_code || g_batch_info_rec.prod_manufactured_date    -- �����i_���Y��
                    || cv_separate_code || g_batch_info_rec.prod_material_stored_date -- �����i_�������ɓ�
                    || cv_separate_code || g_batch_info_rec.prod_actual_qty           -- �����i_���ѐ���
                    || cv_separate_code || g_batch_info_rec.prod_item_um              -- �����i_�P��
                    || cv_separate_code || g_batch_info_rec.prod_rank1                -- �����i_�����N�P
                    || cv_separate_code || g_batch_info_rec.prod_rank2                -- �����i_�����N�Q
                    || cv_separate_code || g_batch_info_rec.prod_rank3                -- �����i_�����N�R
                    || cv_separate_code || g_batch_info_rec.prod_discription          -- �����i_�E�v
                    || cv_separate_code || g_batch_info_rec.prod_in_qty               -- �����i_�݌ɓ���
                    || cv_separate_code || g_batch_info_rec.prod_request_qty          -- �����i_�˗�����
                    || cv_separate_code || g_batch_info_rec.prod_instruct_qty         -- �����i_�w�}����
                    || cv_separate_code || g_batch_info_rec.prod_move_location        -- �����i_�ړ��ꏊ�R�[�h
                    || cv_separate_code || TO_CHAR(g_batch_info_rec.h_last_update_date, cv_fmt_date) -- �w�b�_�ŏI�X�V��
                    || cv_separate_code || ''  -- ���C��NO
                    || cv_separate_code || ''  -- �i�ڃR�[�h
                    || cv_separate_code || ''  -- ���b�gNO
                    || cv_separate_code || ''  -- �����N����
                    || cv_separate_code || ''  -- �ŗL�L��
                    || cv_separate_code || ''  -- �ܖ�������
                    || cv_separate_code || ''  -- ���C���^�C�v
                    || cv_separate_code || ''  -- �^�C�v
                    || cv_separate_code || ''  -- �������敪
                    || cv_separate_code || ''  -- �ō��敪
                    || cv_separate_code || ''  -- ���Y��
                    || cv_separate_code || ''  -- �������ɓ�
                    || cv_separate_code || ''  -- �P��
                    || cv_separate_code || ''  -- �����N�P
                    || cv_separate_code || ''  -- �����N�Q
                    || cv_separate_code || ''  -- �����N�R
                    || cv_separate_code || ''  -- �E�v
                    || cv_separate_code || ''  -- �݌ɓ���
                    || cv_separate_code || ''  -- �˗�����
                    || cv_separate_code || ''  -- �����폜�t���O
                    || cv_separate_code || ''  -- ���b�g_�w������
                    || cv_separate_code || ''  -- ���b�g_��������
                    || cv_separate_code || ''  -- ���b�g_�\��敪
                    || cv_separate_code || ''  -- ���b�g_�\��ԍ�
                    || cv_separate_code || ''  -- ���׍ŏI�X�V��
        ;
--
        -- �t�@�C���o��
        UTL_FILE.PUT_LINE(
          lf_file_hand
         ,lv_csv_data
        );
--
      END IF;
--
      -- ���׍s
      lv_csv_data :=                     cv_coop_name_itoen          -- ��Ж�
                  || cv_separate_code || cv_data_type_700            -- �f�[�^���
                  || cv_separate_code || cv_branch_no_20             -- �`���p�}��
                  || cv_separate_code || g_batch_info_rec.batch_no   -- �o�b�`NO
                  || cv_separate_code || g_batch_info_rec.plant_code -- �v�����g�R�[�h
                  || cv_separate_code || ''  -- �H��
                  || cv_separate_code || ''  -- �Ɩ��X�e�[�^�X
                  || cv_separate_code || ''  -- �v�抮����
                  || cv_separate_code || ''  -- ���ъ�����
                  || cv_separate_code || ''  -- �폜�}�[�N
                  || cv_separate_code || ''  -- �`�[�敪
                  || cv_separate_code || ''  -- ���ъǗ�����
                  || cv_separate_code || ''  -- �����i_�i�ڃR�[�h
                  || cv_separate_code || ''  -- �����i_���b�gNO
                  || cv_separate_code || ''  -- �����i_�^�C�v
                  || cv_separate_code || ''  -- �����i_�����N����
                  || cv_separate_code || ''  -- �����i_�ŗL�L��
                  || cv_separate_code || ''  -- �����i_�ܖ�������
                  || cv_separate_code || ''  -- �����i_���Y��
                  || cv_separate_code || ''  -- �����i_�������ɓ�
                  || cv_separate_code || ''  -- �����i_���ѐ���
                  || cv_separate_code || ''  -- �����i_�P��
                  || cv_separate_code || ''  -- �����i_�����N�P
                  || cv_separate_code || ''  -- �����i_�����N�Q
                  || cv_separate_code || ''  -- �����i_�����N�R
                  || cv_separate_code || ''  -- �����i_�E�v
                  || cv_separate_code || ''  -- �����i_�݌ɓ���
                  || cv_separate_code || ''  -- �����i_�˗�����
                  || cv_separate_code || ''  -- �����i_�w�}����
                  || cv_separate_code || ''  -- �����i_�ړ��ꏊ�R�[�h
                  || cv_separate_code || ''  -- �w�b�_�ŏI�X�V��
                  || cv_separate_code || g_batch_info_rec.line_no               -- ���C��NO
                  || cv_separate_code || g_batch_info_rec.item_no               -- �i�ڃR�[�h
                  || cv_separate_code || g_batch_info_rec.lot_no                -- ���b�gNO
                  || cv_separate_code || g_batch_info_rec.producted_date        -- �����N����
                  || cv_separate_code || g_batch_info_rec.uniqe_sign            -- �ŗL�L��
                  || cv_separate_code || g_batch_info_rec.use_by_date           -- �ܖ�������
                  || cv_separate_code || g_batch_info_rec.line_type             -- ���C���^�C�v
                  || cv_separate_code || g_batch_info_rec.item_type             -- �^�C�v
                  || cv_separate_code || g_batch_info_rec.inlet_type            -- �������敪
                  || cv_separate_code || g_batch_info_rec.actual_qty            -- �ō��敪
                  || cv_separate_code || g_batch_info_rec.manufactured_date     -- ���Y��
                  || cv_separate_code || g_batch_info_rec.material_stored_date  -- �������ɓ�
                  || cv_separate_code || g_batch_info_rec.item_um               -- �P��
                  || cv_separate_code || g_batch_info_rec.rank1                 -- �����N�P
                  || cv_separate_code || g_batch_info_rec.rank2                 -- �����N�Q
                  || cv_separate_code || g_batch_info_rec.rank3                 -- �����N�R
                  || cv_separate_code || g_batch_info_rec.discription           -- �E�v
                  || cv_separate_code || g_batch_info_rec.in_qty                -- �݌ɓ���
                  || cv_separate_code || g_batch_info_rec.request_qty           -- �˗�����
                  || cv_separate_code || g_batch_info_rec.material_del_flag     -- �����폜�t���O
                  || cv_separate_code || g_batch_info_rec.lot_instruct_qty      -- ���b�g_�w������
                  || cv_separate_code || g_batch_info_rec.lot_input_qty         -- ���b�g_��������
                  || cv_separate_code || g_batch_info_rec.lot_plan_type         -- ���b�g_�\��敪
                  || cv_separate_code || g_batch_info_rec.lot_plan_num          -- ���b�g_�\��ԍ�
                  || cv_separate_code || TO_CHAR(g_batch_info_rec.l_last_update_date, cv_fmt_date) -- ���׍ŏI�X�V��
      ;
--
      -- �t�@�C���o��
      UTL_FILE.PUT_LINE(
        lf_file_hand
       ,lv_csv_data
      );
--
      -- �L�[���ڂ�ێ�
      lt_prev_batch_no   := g_batch_info_rec.batch_no;
--
      -- �Ώی������J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
    END LOOP batch_info_loop;
--
    --==================================
    -- �t�@�C���N���[�Y
    --==================================
    UTL_FILE.FCLOSE( lf_file_hand );
--
    -- �Ώی�����0���̏ꍇ
    IF ( gn_target_cnt = 0 ) THEN
      -- �Ώۃf�[�^���擾�G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(
               iv_application => cv_app_xxcmn
              ,iv_name        => cv_msg_xxcmn_11048
             );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      --1�s��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => NULL
      );
--
      -- �X�e�[�^�X�x��
      ov_retcode := cv_status_warn;
--
    ELSE
    -- �Ώی��������݂���ꍇ
      --==================================
      -- ���[�N�t���[�ʒm
      --==================================
      xxwsh_common3_pkg.wf_whs_start(
        ir_wf_whs_rec => lr_wf_whs_rec      -- ���[�N�t���[�֘A���
       ,iv_filename   => lv_file_name       -- �t�@�C����
       ,ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_batch_no               IN  VARCHAR2  -- 1.�o�b�`NO
   ,iv_whse_code              IN  VARCHAR2  -- 2.�q�ɃR�[�h
   ,iv_production_date_from   IN  VARCHAR2  -- 3.�����i������(FROM)
   ,iv_production_date_to     IN  VARCHAR2  -- 4.�����i������(TO)
   ,iv_routing                IN  VARCHAR2  -- 5.���C��No
   ,ov_errbuf                 OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                 OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
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
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    --  ��������(A-1)
    -- ===============================
    init(
      iv_batch_no             =>  iv_batch_no             -- 1.�o�b�`NO
     ,iv_whse_code            =>  iv_whse_code            -- 2.�q�ɃR�[�h
     ,iv_production_date_from =>  iv_production_date_from -- 3.�����i������(FROM)
     ,iv_production_date_to   =>  iv_production_date_to   -- 4.�����i������(TO)
     ,iv_routing              =>  iv_routing              -- 5.���C��No
     ,ov_errbuf               =>  lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode              =>  lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg               =>  lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==================================
    -- CSV�o�͏���(A-2)
    --==================================
    output_data(
      iv_batch_no             =>  iv_batch_no             -- 1.�o�b�`NO
     ,iv_whse_code            =>  iv_whse_code            -- 2.�q�ɃR�[�h
     ,iv_production_date_from =>  iv_production_date_from -- 3.�����i������(FROM)
     ,iv_production_date_to   =>  iv_production_date_to   -- 4.�����i������(TO)
     ,iv_routing              =>  iv_routing              -- 5.���C��No
     ,ov_errbuf               =>  lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode              =>  lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg               =>  lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
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
    errbuf                    OUT VARCHAR2        -- �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode                   OUT VARCHAR2        -- ���^�[���E�R�[�h    --# �Œ� #
   ,iv_batch_no               IN  VARCHAR2        -- 1.�o�b�`NO
   ,iv_whse_code              IN  VARCHAR2        -- 2.�q�ɃR�[�h
   ,iv_production_date_from   IN  VARCHAR2        -- 3.�����i������(FROM)
   ,iv_production_date_to     IN  VARCHAR2        -- 4.�����i������(TO)
   ,iv_routing                IN  VARCHAR2        -- 5.���C��No
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
    cv_sts_cd_normal   CONSTANT VARCHAR2(1)   := 'C';                -- �X�e�[�^�X�R�[�h:C(����)
    cv_sts_cd_warn     CONSTANT VARCHAR2(1)   := 'G';                -- �X�e�[�^�X�R�[�h:G(�x��)
    cv_sts_cd_error    CONSTANT VARCHAR2(1)   := 'E';                -- �X�e�[�^�X�R�[�h:E(�G���[)
--
    cv_appl_name_xxcmn CONSTANT VARCHAR2(10)  := 'XXCMN';            -- �A�h�I���F���Y(�}�X�^�E�o���E����)
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCMN-00008';  -- ��������
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCMN-00009';  -- ��������
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCMN-00010';  -- �G���[����
    cv_out_msg         CONSTANT VARCHAR2(100) := 'APP-XXCMN-00012';  -- �I�����b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'CNT';              -- �������b�Z�[�W�p�g�[�N����
    cv_status_token    CONSTANT VARCHAR2(10)  := 'STATUS';           -- �����X�e�[�^�X�p�g�[�N����
    cv_cp_status_cd    CONSTANT VARCHAR2(100) := 'CP_STATUS_CODE';   -- ���b�N�A�b�v
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
       ov_retcode =>  lv_retcode
      ,ov_errbuf  =>  lv_errbuf
      ,ov_errmsg  =>  lv_errmsg
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
      iv_batch_no             =>  iv_batch_no             -- 1.�o�b�`NO
     ,iv_whse_code            =>  iv_whse_code            -- 2.�q�ɃR�[�h
     ,iv_production_date_from =>  iv_production_date_from -- 3.�����i������(FROM)
     ,iv_production_date_to   =>  iv_production_date_to   -- 4.�����i������(TO)
     ,iv_routing              =>  iv_routing              -- 5.���C��No
     ,ov_errbuf               =>  lv_errbuf               -- �G���[�E���b�Z�[�W             --# �Œ� #
     ,ov_retcode              =>  lv_retcode              -- ���^�[���E�R�[�h               --# �Œ� #
     ,ov_errmsg               =>  lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
    -- �X�e�[�^�X���G���[�̏ꍇ
      -- �����ݒ�
      gn_target_cnt := 0;  -- ��������
      gn_normal_cnt := 0;  -- ��������
      gn_error_cnt  := 1;  -- �G���[����
--
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- ��s���o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
    ELSIF ( lv_retcode = cv_status_warn ) THEN
    -- �X�e�[�^�X���x���̏ꍇ(�Ώۃf�[�^�����̏ꍇ)
      -- �����ݒ�
      gn_target_cnt := 0; -- ��������
      gn_normal_cnt := 0; -- ��������
      gn_error_cnt  := 0; -- �G���[����
    ELSE
    -- �X�e�[�^�X������̏ꍇ
      -- �����ݒ�
      gn_normal_cnt := gn_target_cnt; -- ��������
      gn_error_cnt  := 0;             -- �G���[����
    END IF;
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn
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
    gv_out_msg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn
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
    gv_out_msg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ��s���o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_space
    );
--
    -- �I���X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = cv_cp_status_cd
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            cv_status_normal,cv_sts_cd_normal,
                                            cv_status_warn,cv_sts_cd_warn,
                                            cv_sts_cd_error)
    AND    ROWNUM                  = 1
    ;
    gv_out_msg := xxcmn_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcmn
                   ,iv_name         => cv_out_msg
                   ,iv_token_name1  => cv_status_token
                   ,iv_token_value1 => gv_conc_status
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�I���X�e�[�^�X�Z�b�g
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
END XXCMN800014C;
/
