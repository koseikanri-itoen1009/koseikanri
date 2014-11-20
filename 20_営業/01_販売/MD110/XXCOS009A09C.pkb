CREATE OR REPLACE PACKAGE BODY APPS.XXCOS009A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS009A09C (spec)
 * Description      : �󒍈ꗗ���s��CSV�o��
 * MD.050           : �󒍈ꗗ���s��CSV�o�� MD050_COS_009_A09
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_order_list_cond    �󒍈ꗗ���s�󋵃f�[�^���o(A-2)
 *  output_data            �f�[�^�o��(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/09/12    1.0   M.Takasaki       �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                    -- �Ώی���
  gn_normal_cnt             NUMBER;                    -- ���팏��
  gn_error_cnt              NUMBER;                    -- �G���[����
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
  --*** �o�͓� ���t�t�]�`�F�b�N��O ***
  global_date_rever_old_chk_expt    EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) :=  'XXCOS009A09C';        -- �p�b�P�[�W��
  cv_xxcos_short_name       CONSTANT  VARCHAR2(100) :=  'XXCOS';               -- �̕��̈�Z�k�A�v����
  --���b�Z�[�W
  cv_msg_date_rever_err     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00005';    -- ���t�t�]�G���[���b�Z�[�W
  cv_msg_proc_date_err      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00014';    -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_parameter          CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14454';    -- �p�����[�^�o�̓��b�Z�[�W
  --�g�[�N����
  cv_tkn_nm_base_code       CONSTANT  VARCHAR2(100) :=  'BASE_CODE';           -- ���_�R�[�h
  cv_tkn_nm_date_from       CONSTANT  VARCHAR2(100) :=  'DATE_FROM';           -- �o�͓�(FROM)
  cv_tkn_nm_date_to         CONSTANT  VARCHAR2(100) :=  'DATE_TO';             -- �o�͓�(TO)
  --�g�[�N���l
  cv_msg_vl_order_li_basecd CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14451';    -- ���_�R�[�h
  cv_msg_vl_order_li_from   CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14452';    -- �o�͓�(FROM)
  cv_msg_vl_order_li_to     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14453';    -- �o�͓�(TO)
  --�󒍈ꗗ�o�͊Ǘ��e�[�u���擾�p
  cv_class_base             CONSTANT  VARCHAR2(2)   := '1';    -- �ڋq�敪:���_
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_proc_date              DATE;                                              --�Ɩ����t
  -- ===============================
  -- ���[�U�[��`�O���[�o���E�J�[�\��
  -- ===============================
  -- �󒍈ꗗ�o�͊Ǘ��e�[�u���擾
  CURSOR get_order_list_data_cur(
           ip_base_code               VARCHAR,  -- ���_�R�[�h
           ip_order_list_date_from    DATE,     -- �o�͓�(FROM)
           ip_order_list_date_to      DATE)     -- �o�͓�(TO)
  IS
    SELECT    xolc.delivery_base_code As base_code                   -- �󒍈ꗗ�o�͊Ǘ��e�[�u��.���_�R�[�h
             ,hp_ba.party_name        AS base_code_name              -- �p�[�e�B�}�X�^_���_.����           �F���_��
             ,TO_CHAR(xolc.output_datetime,'YYYY/MM/DD HH24:MI:SS')
                                      AS output_datetime             -- �󒍈ꗗ�o�͊Ǘ��e�[�u��.�o�͎���
             ,papf.per_information18 || papf.per_information19
                                      AS creater_name                -- �]�ƈ��}�X�^.������ + ������       �F�o�͎�
             ,xolc.chain_code         AS chain_code                  -- �󒍈ꗗ�o�͊Ǘ��e�[�u��.�`�F�[���X�R�[�h
             ,xolc.chain_name         AS chain_name                  -- �󒍈ꗗ�o�͊Ǘ��e�[�u��.�`�F�[���X��
             ,xolc.store_code         AS store_code                  -- �󒍈ꗗ�o�͊Ǘ��e�[�u��.�X�܃R�[�h
             ,xolc.invoice_number     AS invoice_number              -- �󒍈ꗗ�o�͊Ǘ��e�[�u��.�`�[�ԍ�
             ,xolc.order_number       AS order_number                -- �󒍈ꗗ�o�͊Ǘ��e�[�u��.�󒍔ԍ�
             ,xolc.request_id         AS con_number                  -- �󒍈ꗗ�o�͊Ǘ��e�[�u��.�v��ID    �F�R���J�����g�ԍ�
    FROM      xxcos_order_list_conditions xolc                       -- �󒍈ꗗ�o�͊Ǘ��e�[�u��
             ,hz_parties                  hp_ba                      -- �p�[�e�B�}�X�^_���_
             ,hz_cust_accounts            hca_ba                     -- �ڋq�}�X�^_���_
             ,per_all_people_f            papf                       -- �]�ƈ��}�X�^
             ,fnd_user                    fu                         -- ���[�U�[�}�X�^
    WHERE    -- �o�͎��Ԃ��p�����[�^�̊��ԓ� ���A���_�R�[�h���p�����[�^�Ɠ���
             TRUNC(xolc.output_datetime) >= ip_order_list_date_from  -- �󒍈ꗗ�o�͊Ǘ��e�[�u��.�o�͎���   �� �p�����[�^.�o�͓�(FROM)
    AND      TRUNC(xolc.output_datetime) <= ip_order_list_date_to    -- �󒍈ꗗ�o�͊Ǘ��e�[�u��.�o�͎���   �� �p�����[�^.�o�͓�(TO)
    AND      xolc.delivery_base_code = ip_base_code                  -- �󒍈ꗗ�o�͊Ǘ��e�[�u��.���_�R�[�h �� �p�����[�^�D���_�R�[�h
    AND      xolc.delivery_base_code = hca_ba.account_number         -- �󒍈ꗗ�o�͊Ǘ��e�[�u��.���_�R�[�h �� �ڋq�}�X�^_���_.�ڋq�R�[�h
    AND      hca_ba.customer_class_code  =  cv_class_base            -- �ڋq�}�X�^_���_.�ڋq�敪            �� '1'    �F���_
    AND      hca_ba.party_id  =  hp_ba.party_id                      -- �ڋq�}�X�^_���_.�p�[�e�BID          �� �p�[�e�B�}�X�^_���_.�p�[�e�BID
    AND      xolc.created_by = fu.user_id                            -- �󒍈ꗗ�o�͊Ǘ��e�[�u��.�쐬��     �� ���[�U�[�}�X�^.���[�U�[ID
    AND      papf.person_id = fu.employee_id                         -- �]�ƈ��}�X�^.�]�ƈ�ID               �� ���[�U�[�}�X�^.�]�ƈ�ID
    AND      TRUNC(xolc.output_datetime) >= TRUNC(papf.effective_start_date)  -- �󒍈ꗗ�o�͊Ǘ��e�[�u��.�o�͎���   �� �]�ƈ��}�X�^.�L���J�n��
    AND      TRUNC(xolc.output_datetime) <= TRUNC(papf.effective_end_date)    -- �󒍈ꗗ�o�͊Ǘ��e�[�u��.�o�͎���   �� �]�ƈ��}�X�^.�L���I����
    ORDER BY
       xolc.delivery_base_code                                       -- ���_�R�[�h
      ,xolc.output_datetime                                          -- �o�͎���
      ,xolc.chain_code                                               -- �`�F�[���X
      ,xolc.store_code                                               -- �X��
      ,xolc.invoice_number                                           -- �`�[�ԍ�
  ;
  --�擾�f�[�^�i�[�ϐ���`
  TYPE g_out_file_ttype IS TABLE OF get_order_list_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_out_file_tab       g_out_file_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code                    IN     VARCHAR2,  -- 1.���_�R�[�h
    iv_order_list_date_from         IN     VARCHAR2,  -- 2.�o�͓�(FROM)
    iv_order_list_date_to           IN     VARCHAR2,  -- 3.�o�͓�(TO)
    od_order_list_date_from         OUT    DATE,      -- 1.�o�͓�(FROM)_�`�F�b�NOK
    od_order_list_date_to           OUT    DATE,      -- 2.�o�͓�(TO)_�`�F�b�NOK
    ov_errbuf                       OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_para_msg                     VARCHAR2(5000);     -- �p�����[�^�o�̓��b�Z�[�W
    lv_check_d_from                 VARCHAR2(100);      -- �o�͓�(FROM)����
    lv_check_d_to                   VARCHAR2(100);      -- �o�͓�(TO)����
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
    --========================================
    -- �p�����[�^�o�͏���
    --========================================
    lv_para_msg             :=  xxccp_common_pkg.get_msg(
      iv_application        =>  cv_xxcos_short_name,
      iv_name               =>  cv_msg_parameter,
      iv_token_name1        =>  cv_tkn_nm_base_code,
      iv_token_value1       =>  iv_base_code,
      iv_token_name2        =>  cv_tkn_nm_date_from,
      iv_token_value2       =>  iv_order_list_date_from,
      iv_token_name3        =>  cv_tkn_nm_date_to,
      iv_token_value3       =>  iv_order_list_date_to
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    od_order_list_date_from   := TO_DATE( iv_order_list_date_from, 'RRRR/MM/DD' );  -- �o�͓� (FROM)
    od_order_list_date_to     := TO_DATE( iv_order_list_date_to, 'RRRR/MM/DD' );    -- �o�͓�(TO)
    --
    --========================================
    -- 1.���̓p�����[�^�`�F�b�N
    --========================================
    -- �o�͓�(FROM)�^ �o�͓�(TO)  ���t�t�]�`�F�b�N
    IF ( od_order_list_date_from > od_order_list_date_to ) THEN
      RAISE global_date_rever_old_chk_expt;
    END IF;
    --========================================
    -- 2.�Ɩ����t�擾����
    --========================================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- ***�o�͓� ���t�t�]�`�F�b�N��O�n���h�� ***
    WHEN global_date_rever_old_chk_expt THEN
      lv_check_d_from         :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_li_from
      );
      lv_check_d_to           :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_li_to
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_rever_err,
        iv_token_name1        =>  cv_tkn_nm_date_from,
        iv_token_value1       =>  lv_check_d_from,
        iv_token_name2        =>  cv_tkn_nm_date_to,
        iv_token_value2       =>  lv_check_d_to
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_order_list_cond
   * Description      : �󒍈ꗗ���s�󋵃f�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE get_order_list_cond(
    iv_base_code                    IN     VARCHAR2,  -- 1.���_�R�[�h
    id_order_list_date_from         IN     DATE,      -- 2.�o�͓�(FROM)_�`�F�b�NOK
    id_order_list_date_to           IN     DATE,      -- 3.�o�͓�(TO)_�`�F�b�NOK
    ov_errbuf                       OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_list_cond'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�Ώۃf�[�^�擾
    OPEN get_order_list_data_cur(
             iv_base_code,                 --���_�R�[�h
             id_order_list_date_from,      --�o�͓�(FROM)
             id_order_list_date_to);       --�o�͓�(TO)
    FETCH get_order_list_data_cur BULK COLLECT INTO gt_out_file_tab;
    CLOSE get_order_list_data_cur;
    --���������J�E���g
    gn_target_cnt := gt_out_file_tab.COUNT;
--
--
  EXCEPTION
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
  END get_order_list_cond;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : �f�[�^�o��(A-3)
   ***********************************************************************************/
  PROCEDURE output_data(
    ov_errbuf                       OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- �v���O������
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
    ct_enabled_flg_y        CONSTANT  fnd_lookup_values.enabled_flag%TYPE
                                                    :=  'Y';                          --�g�p�\
    cv_lang                 CONSTANT  VARCHAR2(100) :=  USERENV( 'LANG' );            --����
    cv_type_head            CONSTANT  VARCHAR2(100) := 'XXCOS1_EXCEL_OUTPUT_HEAD';    --�G�N�Z���o�͗p���o��
    cv_code_eoh_009a09      CONSTANT  VARCHAR2(100) := '009A09%';                     --�G�N�Z���o�͗p���o���̃N�C�b�N�R�[�h
    cv_delimit              CONSTANT  VARCHAR2(10)  := ',';                           -- ��؂蕶��
    cv_enclosed             CONSTANT  VARCHAR2(2)   := '"';                           -- �P��͂ݕ���
--
    -- *** ���[�J���ϐ� ***
    lv_line_data            VARCHAR2(5000);         -- OUTPUT�f�[�^�ҏW�p
--
    -- *** ���[�J���E�J�[�\�� ***
    --���o���擾�p�J�[�\��
    CURSOR head_cur
    IS
      SELECT  flv.description  head
      FROM    fnd_lookup_values flv
      WHERE   flv.language      = cv_lang
      AND     flv.lookup_type   = cv_type_head
      AND     lookup_code    LIKE cv_code_eoh_009a09
      AND     gd_proc_date     >= NVL( flv.start_date_active, gd_proc_date )
      AND     gd_proc_date     <= NVL( flv.end_date_active,   gd_proc_date )
      AND     flv.enabled_flag  = ct_enabled_flg_y
      ORDER BY
              flv.lookup_code
      ;
    --���o��
    TYPE l_head_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�e�[�u�� ***
    lt_head_tab l_head_ttype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ------------------------------------------
    -- ���o���̏o��
    ------------------------------------------
    -- �f�[�^�̌��o�����擾
    OPEN  head_cur;
    FETCH head_cur BULK COLLECT INTO lt_head_tab;
    CLOSE head_cur;
--
    --�f�[�^�̌��o����ҏW
    <<data_head_output>>
    FOR i IN 1..lt_head_tab.COUNT LOOP
      IF ( i = 1 ) THEN
        lv_line_data := lt_head_tab(i);
      ELSE
        lv_line_data := lv_line_data || cv_delimit || lt_head_tab(i);
      END IF;
    END LOOP data_head_output;
--
    --�f�[�^�̌��o�����o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_line_data
    );
    ------------------------------------------
    -- �f�[�^�o��
    ------------------------------------------
    <<data_output>>
    FOR i IN 1..gt_out_file_tab.COUNT LOOP
      --�f�[�^��ҏW
      lv_line_data :=     cv_enclosed || gt_out_file_tab(i).base_code       || cv_enclosed  -- ���_�R�[�h
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).base_code_name  || cv_enclosed  -- ���_��
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).output_datetime || cv_enclosed  -- �o�͎���
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).creater_name    || cv_enclosed  -- �o�͎�
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).chain_code      || cv_enclosed  -- �`�F�[���X�R�[�h
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).chain_name      || cv_enclosed  -- �`�F�[���X��
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).store_code      || cv_enclosed  -- �X�܃R�[�h
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).invoice_number  || cv_enclosed  -- �`�[�ԍ�
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).order_number    || cv_enclosed  -- �󒍔ԍ�
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).con_number      || cv_enclosed  -- �R���J�����g�ԍ�
      ;
      --�f�[�^���o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
      --���������J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP data_output;
--
  EXCEPTION
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
    iv_base_code                    IN     VARCHAR2,  --   1.���_�R�[�h
    iv_order_list_date_from         IN     VARCHAR2,  --   2.�o�͓�(FROM)
    iv_order_list_date_to           IN     VARCHAR2,  --   3.�o�͓�(TO)
    ov_errbuf                       OUT    VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ld_order_list_date_from         DATE;             -- �o�͓�(FROM)_�`�F�b�NOK
    ld_order_list_date_to           DATE;             -- �o�͓�(TO)_�`�F�b�NOK
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
    -- ===============================
    -- A-1  ��������
    -- ===============================
    init(
      iv_base_code,                 -- ���_�R�[�h
      iv_order_list_date_from,      -- �o�͓�(FROM)
      iv_order_list_date_to,        -- �o�͓�(TO)
      ld_order_list_date_from,      -- �o�͓�(FROM)_�`�F�b�NOK
      ld_order_list_date_to,        -- �o�͓�(TO)_�`�F�b�NOK
      lv_errbuf,                    -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                   -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  �󒍈ꗗ���s�󋵃f�[�^���o
    -- ===============================
    get_order_list_cond(
      iv_base_code,                 -- ���_�R�[�h
      ld_order_list_date_from,      -- �o�͓�(FROM)_�`�F�b�NOK
      ld_order_list_date_to,        -- �o�͓�(TO)_�`�F�b�NOK
      lv_errbuf,                    -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                   -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  �f�[�^�o��
    -- ===============================
    output_data(
      lv_errbuf,                    -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                   -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
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
    errbuf                          OUT    VARCHAR2,  --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                         OUT    VARCHAR2,  --   ���^�[���E�R�[�h    --# �Œ� #
    iv_base_code                    IN     VARCHAR2,  --   1.���_�R�[�h
    iv_order_list_date_from         IN     VARCHAR2,  --   2.�o�͓�(FROM)
    iv_order_list_date_to           IN     VARCHAR2   --   3.�o�͓�(TO)
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O
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
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_base_code                    -- ���_�R�[�h
      ,iv_order_list_date_from         -- �o�͓�(FROM)
      ,iv_order_list_date_to           -- �o�͓�(TO)
      ,lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF ( lv_retcode <> cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
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
    --
    --�G���[�̏ꍇ�A���������N���A
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
    END IF;
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
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
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
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
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
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
    IF ( retcode = cv_status_error ) THEN
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
END XXCOS009A09C;
/