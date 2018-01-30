CREATE OR REPLACE PACKAGE BODY XXCOI010A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCOI010A06C(body)
 * Description      : �H����ɏ��HHT�A�g
 * MD.050           : �H����ɏ��HHT�A�g <MD050_COI_010_A06>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  create_csv             �Ώۃf�[�^���o����CSV�쐬 (A-2,A-3,A-4)
 *  submain                ���C�������v���V�[�W�� (A-5)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/01/12    1.0   SCSK���X��       �V�K�쐬(E_�{�ғ�_14486�Ή�)
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
  procedure_common_expt     EXCEPTION;      --  ���[�U��`���b�Z�[�W�o�͗p���ʗ�O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100)  :=  'XXCOI010A06C';           --  �p�b�P�[�W��
  cv_appl_short_name_xxcoi    CONSTANT VARCHAR2(10)   :=  'XXCOI';                  --  �A�v���P�[�V�����Z�k���FXXCOI
  --  ���b�Z�[�W�E�g�[�N��
  cv_msg_xxcoi1_10316         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10316';       --  �p�����[�^.�����Ώۓ�
  cv_msg_xxcoi1_00011         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00011';       --  �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_00003         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00003';       --  �f�B���N�g�����擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_00029         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00029';       --  �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_00004         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00004';       --  �t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_00028         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00028';       --  �t�@�C�����o�̓��b�Z�[�W
  cv_msg_xxcoi1_00027         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00027';       --  �t�@�C�����݃`�F�b�N�G���[
  cv_msg_xxcoi1_00008         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00008';       --  �Ώۃf�[�^�������b�Z�[�W
  cv_msg_xxcoi1_10521         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10521';       --  �ۊǏꏊ���擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10380         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10380';       --  �q�ɕۊǏꏊ�d���G���[
  cv_tkn_xxcoi1_10316_1       CONSTANT VARCHAR2(30)   :=  'P_DATE';                 --  APP-XXCOI1-10316�pTOKEN
  cv_tkn_xxcoi1_00003_1       CONSTANT VARCHAR2(30)   :=  'PRO_TOK';                --  APP-XXCOI1-00003�pTOKEN
  cv_tkn_xxcoi1_00029_1       CONSTANT VARCHAR2(30)   :=  'DIR_TOK';                --  APP-XXCOI1-00029�pTOKEN
  cv_tkn_xxcoi1_00004_1       CONSTANT VARCHAR2(30)   :=  'PRO_TOK';                --  APP-XXCOI1-00004�pTOKEN
  cv_tkn_xxcoi1_00028_1       CONSTANT VARCHAR2(30)   :=  'FILE_NAME';              --  APP-XXCOI1-00028�pTOKEN
  cv_tkn_xxcoi1_00027_1       CONSTANT VARCHAR2(30)   :=  'FILE_NAME';              --  APP-XXCOI1-00027�pTOKEN
  cv_tkn_xxcoi1_10521_1       CONSTANT VARCHAR2(30)   :=  'BASE_CODE';              --  APP-XXCOI1-10521�pTOKEN
  cv_tkn_xxcoi1_10521_2       CONSTANT VARCHAR2(30)   :=  'SUBINV_CODE';            --  APP-XXCOI1-10521�pTOKEN
  cv_tkn_xxcoi1_10380_1       CONSTANT VARCHAR2(30)   :=  'DEPT_CODE';              --  APP-XXCOI1-10380�pTOKEN
  cv_tkn_xxcoi1_10380_2       CONSTANT VARCHAR2(30)   :=  'WHOUSE_CODE';            --  APP-XXCOI1-10380�pTOKEN
  --  �v���t�@�C��
  cv_profile_dire_out_hht     CONSTANT VARCHAR2(30)   :=  'XXCOI1_DIRE_OUT_HHT';    --  XXCOI:HHT_OUTBOUND�i�[�f�B���N�g���p�X
  cv_profile_factory_hht      CONSTANT VARCHAR2(30)   :=  'XXCOI1_FILE_FACTORYHHT'; --  XXCOI:�H����ɏ��HHT�A�g�t�@�C����
  --
  cv_param_none               CONSTANT VARCHAR2(10)   :=  '�Ȃ�';                   --  �p�����[�^���ݒ�
  cv_slip_type_10             CONSTANT VARCHAR2(2)    :=  '10';                     --  �`�[�敪 10:�H�����
  cv_subinv_type_1            CONSTANT VARCHAR2(1)    :=  '1';                      --  �ۊǏꏊ�敪 1:�q��
  cv_subinv_type_3            CONSTANT VARCHAR2(1)    :=  '3';                      --  �ۊǏꏊ�敪 3:�a����
  cv_subinv_type_4            CONSTANT VARCHAR2(1)    :=  '4';                      --  �ۊǏꏊ�敪 4:���X
  cv_slash                    CONSTANT VARCHAR2(1)    :=  '/';
  cv_comma                    CONSTANT VARCHAR2(1)    :=  ',';
  cv_dquot                    CONSTANT VARCHAR2(1)    :=  '"';
  cv_yes                      CONSTANT VARCHAR2(1)    :=  'Y';
  cv_no                       CONSTANT VARCHAR2(1)    :=  'N';
  cv_utlfile_open_w           CONSTANT VARCHAR2(1)    :=  'w';                      --  �I�[�v�����[�h w:��������
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_param_target_date        DATE;                                                 --  �p�����[�^.�����Ώۓ�
  gd_process_date             DATE;                                                 --  �Ɩ����t
  g_file_handle               UTL_FILE.FILE_TYPE;                                   --  �t�@�C���n���h��

--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_target_date    IN  VARCHAR2      --  �p�����[�^�F�����Ώۓ�
    , ov_errbuf         OUT VARCHAR2      --  �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode        OUT VARCHAR2      --  ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg         OUT VARCHAR2      --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  ) IS
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
    lv_dire_name      VARCHAR2(50);                             --  �f�B���N�g����
    lt_dire_path      all_directories.directory_path%TYPE;      --  �f�B���N�g���p�X
    lv_file_name      VARCHAR2(50);                             --  �t�@�C����
    lb_fexists        BOOLEAN;                                  --  �t�@�C�����݃`�F�b�N����
    ln_file_length    NUMBER;                                   --  �t�@�C���̒����̕ϐ�
    ln_block_size     NUMBER;                                   --  �u���b�N�T�C�Y�̕ϐ�
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
    --  ������
    lv_dire_name      :=  NULL;           --  �f�B���N�g����
    lt_dire_path      :=  NULL;           --  �f�B���N�g���p�X
    lv_file_name      :=  NULL;           --  �t�@�C����
    lb_fexists        :=  FALSE;          --  �t�@�C�����݃`�F�b�N����
    ln_file_length    :=  NULL;           --  �t�@�C���̒����̕ϐ�
    ln_block_size     :=  NULL;           --  �u���b�N�T�C�Y�̕ϐ�
    gd_process_date   :=  NULL;
    g_file_handle     :=  NULL;
    --
    -- ===================================
    --  �R���J�����g���̓p�����[�^�o��
    -- ===================================
    gv_out_msg  :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_10316
                      , iv_token_name1    =>  cv_tkn_xxcoi1_10316_1
                      , iv_token_value1   =>  CASE  WHEN  iv_target_date IS NOT NULL
                                                      THEN  iv_target_date
                                                      ELSE  cv_param_none
                                              END
                    );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  gv_out_msg
    );
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.LOG
      , buff    =>  gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  ''
    );
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.LOG
      , buff    =>  ''
    );
    --
    -- ===================================
    --  �p�����[�^�ێ�
    -- ===================================
    gd_param_target_date  :=  TO_DATE( iv_target_date, 'YYYY/MM/DD HH24:MI:SS' );
    --
    -- ===================================
    --  �Ɩ����t�擾
    -- ===================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      --  �Ɩ����t���擾�ł��Ȃ��ꍇ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00011
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE procedure_common_expt;
    END IF;
    --
    -- ===================================
    --  �f�B���N�g�����擾
    -- ===================================
    lv_dire_name  :=  fnd_profile.value( cv_profile_dire_out_hht );
    IF ( lv_dire_name IS NULL ) THEN
      --  �f�B���N�g�������擾�ł��Ȃ��ꍇ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00003
                      , iv_token_name1    =>  cv_tkn_xxcoi1_00003_1
                      , iv_token_value1   =>  cv_profile_dire_out_hht
                    );
      lv_errbuf := lv_errmsg;
      RAISE procedure_common_expt;
    END IF;
    --
    -- ===================================
    --  �f�B���N�g���p�X�擾
    -- ===================================
    BEGIN
      SELECT  ad.directory_path
      INTO    lt_dire_path
      FROM    all_directories     ad
      WHERE   ad.directory_name   =   lv_dire_name
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --  �f�B���N�g���p�X���擾�ł��Ȃ��ꍇ
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_appl_short_name_xxcoi
                        , iv_name           =>  cv_msg_xxcoi1_00029
                        , iv_token_name1    =>  cv_tkn_xxcoi1_00029_1
                        , iv_token_value1   =>  lv_dire_name
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE procedure_common_expt;
    END;
    --
    -- ===================================
    --  �t�@�C�����擾
    -- ===================================
    lv_file_name  :=  fnd_profile.value( cv_profile_factory_hht );
    IF ( lv_file_name IS NULL ) THEN
      --  �f�B���N�g�������擾�ł��Ȃ��ꍇ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00004
                      , iv_token_name1    =>  cv_tkn_xxcoi1_00004_1
                      , iv_token_value1   =>  cv_profile_factory_hht
                    );
      lv_errbuf := lv_errmsg;
      RAISE procedure_common_expt;
    END IF;
    --
    -- ===================================
    --  �t�@�C�����o��
    -- ===================================
    -- ���b�Z�[�W����
    gv_out_msg  :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00028
                      , iv_token_name1    =>  cv_tkn_xxcoi1_00028_1
                      , iv_token_value1   =>  lt_dire_path || cv_slash || lv_file_name
                    );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  ''
    );
    --
    -- ===================================
    --  �t�@�C�����݃`�F�b�N
    -- ===================================
    UTL_FILE.FGETATTR(
        location      =>  lv_dire_name
      , filename      =>  lv_file_name
      , fexists       =>  lb_fexists
      , file_length   =>  ln_file_length
      , block_size    =>  ln_block_size
    );
    IF ( lb_fexists ) THEN
      --  �����t�@�C�������݂���ꍇ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00027
                      , iv_token_name1    =>  cv_tkn_xxcoi1_00027_1
                      , iv_token_value1   =>  lv_file_name
                    );
      lv_errbuf := lv_errmsg;
      RAISE procedure_common_expt;
    END IF;
    --
    -- ===================================
    --  �t�@�C��OPEN
    -- ===================================
    g_file_handle :=  UTL_FILE.FOPEN(
                          location    =>  lv_dire_name
                        , filename    =>  lv_file_name
                        , open_mode   =>  cv_utlfile_open_w
                      );
    --
  EXCEPTION
    WHEN procedure_common_expt THEN
      -- *** ���[�U��`���b�Z�[�W�o��<���ʗ�O> ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
   * Procedure Name   : create_csv
   * Description      : �Ώۃf�[�^���o����CSV�쐬 (A-2, A-3, A-4)
   ***********************************************************************************/
  PROCEDURE create_csv(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_csv'; -- �v���O������
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
    ld_disposal_day                 DATE;                       --  ������
    lv_transfer_date                VARCHAR2(21);               --  ���M����
    lt_secondary_inventory_name     mtl_secondary_inventories.secondary_inventory_name%TYPE;
    lv_csv_line                     VARCHAR2(1500);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ===============================
    --  ���ɏ��ꎞ�\���o (A-2)
    -- ===============================
    CURSOR  storage_cur
    IS
      SELECT  xsi.base_code                           AS  "BASE_CODE"               --  ���_�R�[�h
            , xsi.warehouse_code                      AS  "WAREHOUSE_CODE"          --  �q�ɃR�[�h
            , xsi.ship_warehouse_code                 AS  "SHIP_WAREHOUSE_CODE"     --  �]����q�ɃR�[�h
            , xsi.slip_date                           AS  "SLIP_DATE"               --  �`�[���t
            , xsi.parent_item_code                    AS  "PARENT_ITEM_CODE"        --  �e�i�ڃR�[�h
            , SUM( NVL( xsi.ship_summary_qty, 0 ) )   AS  "SHIP_SUMMARY_QTY"        --  ���ɐ��i�o�ɐ���.���v�j
      FROM    xxcoi_storage_information   xsi                                       --  ���ɏ��ꎞ�\
      WHERE   xsi.slip_type                       =   cv_slip_type_10               --  �`�[�敪�F�H�����
      AND     xsi.slip_date                       >=  ld_disposal_day               --  ���ɗ\���
      AND     NVL( xsi.store_check_flag, cv_no )  =   cv_no                         --  ���Ɋm�F�σt���O�F���m�F
      AND     xsi.summary_data_flag               =   cv_yes
      GROUP BY
              xsi.base_code
            , xsi.warehouse_code
            , xsi.ship_warehouse_code
            , xsi.slip_date
            , xsi.parent_item_code
      ;
    -- <���ɏ��ꎞ�\���o>���R�[�h�^
    storage_rec   storage_cur%ROWTYPE;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ld_disposal_day   :=  NVL( gd_param_target_date, gd_process_date + 1 );           --  ������
    lv_transfer_date  :=  TO_CHAR( SYSDATE, 'YYYY/MM/DD HH24:MI:SS' );                --  ���M����
    --
    <<csv_loop>>
    FOR storage_rec IN storage_cur LOOP
      --  �Ώی����J�E���g
      gn_target_cnt                 :=  gn_target_cnt + 1;
      lv_errmsg                     :=  NULL;
      lv_csv_line                   :=  NULL;
      lt_secondary_inventory_name   :=  NULL;
      -- ===============================
      --  �ۊǏꏊ���o (A-3)
      -- ===============================
      BEGIN
        IF ( storage_rec.ship_warehouse_code IS NOT NULL ) THEN
          --  �]����q�ɂ��ݒ肳��Ă���ꍇ
          SELECT  msi.secondary_inventory_name    AS  "SECONDARY_INVENTORY_NAME"    --  �ۊǏꏊ�R�[�h
          INTO    lt_secondary_inventory_name                                       --  �ۊǏꏊ�}�X�^
          FROM    mtl_secondary_inventories     msi
          WHERE   msi.attribute7      =   storage_rec.base_code
          AND     msi.attribute1      =   cv_subinv_type_3        --  �a����
          AND     SUBSTRB( msi.secondary_inventory_name, 6, 5 )   =   storage_rec.ship_warehouse_code
          AND     NVL( msi.disable_date, ld_disposal_day + 1 )    >   ld_disposal_day
          ;
        ELSE
          --  �ݒ肳��Ă��Ȃ��ꍇ
          SELECT  msi.secondary_inventory_name    AS  "SECONDARY_INVENTORY_NAME"    --  �ۊǏꏊ�R�[�h
          INTO    lt_secondary_inventory_name                                       --  �ۊǏꏊ�}�X�^
          FROM    mtl_secondary_inventories     msi
          WHERE   msi.attribute7      =   storage_rec.base_code
          AND     msi.attribute1 IN( cv_subinv_type_1, cv_subinv_type_4 )     --  �q��or���X
          AND     SUBSTRB( msi.secondary_inventory_name, 6, 2 )   =   storage_rec.warehouse_code
          AND     NVL( msi.disable_date, ld_disposal_day + 1 )    >   ld_disposal_day
          ;
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                            iv_application    =>  cv_appl_short_name_xxcoi
                          , iv_name           =>  cv_msg_xxcoi1_10521
                          , iv_token_name1    =>  cv_tkn_xxcoi1_10521_1
                          , iv_token_value1   =>  storage_rec.base_code
                          , iv_token_name2    =>  cv_tkn_xxcoi1_10521_2
                          , iv_token_value2   =>  NVL( storage_rec.ship_warehouse_code, storage_rec.warehouse_code )
                        );
        WHEN TOO_MANY_ROWS THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                            iv_application    =>  cv_appl_short_name_xxcoi
                          , iv_name           =>  cv_msg_xxcoi1_10380
                          , iv_token_name1    =>  cv_tkn_xxcoi1_10380_1
                          , iv_token_value1   =>  storage_rec.base_code
                          , iv_token_name2    =>  cv_tkn_xxcoi1_10380_2
                          , iv_token_value2   =>  NVL( storage_rec.ship_warehouse_code, storage_rec.warehouse_code )
                        );
      END;
      --
      IF ( lv_errmsg IS NOT NULL ) THEN
        --  �ۊǏꏊ�擾�Ɏ��s�����ꍇ�A�x�����b�Z�[�W�o�́A�X�L�b�v����count
        FND_FILE.PUT_LINE(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_errmsg
        );
        gn_warn_cnt :=  gn_warn_cnt + 1;
        ov_retcode  :=  cv_status_warn;
      ELSE
        --  �ۊǏꏊ���擾���ꂽ�ꍇ�ACSV���o�́A���팏��count
        -- ===============================
        --  CSV�쐬 (A-4)
        -- ===============================
        lv_csv_line :=
                            cv_dquot || lt_secondary_inventory_name || cv_dquot     --  �ۊǏꏊ
          ||  cv_comma  ||  TO_CHAR( storage_rec.slip_date, 'YYYYMMDD' )            --  ���ɗ\���
          ||  cv_comma  ||  cv_dquot || storage_rec.parent_item_code || cv_dquot    --  ���i�R�[�h
          ||  cv_comma  ||  TO_CHAR( storage_rec.ship_summary_qty )                 --  ���ɐ�
          ||  cv_comma  ||  cv_dquot || lv_transfer_date || cv_dquot                --  �A�g��
        ;
        -- ===============================
        --  CSV�o�� (A-4)
        -- ===============================
        UTL_FILE.PUT_LINE(
            file    =>  g_file_handle
          , buffer  =>  lv_csv_line
        );
        --
        gn_normal_cnt :=  gn_normal_cnt + 1;
      END IF;
    END LOOP  csv_loop;
    --
    --  �Ώۃf�[�^�����݂��Ȃ��ꍇ�A���O���o��
    IF ( gn_target_cnt = 0 ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00008
                    );
      FND_FILE.PUT_LINE(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  lv_errmsg
      );
      -- ��s�}��
      FND_FILE.PUT_LINE(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  ''
      );
    ELSIF ( gn_warn_cnt <> 0 ) THEN
      -- ��s�}��
      FND_FILE.PUT_LINE(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  ''
      );
    END IF;
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      --  CURSOR��OPEN���Ă���ꍇ�ACLOSE
      IF ( storage_cur%ISOPEN ) THEN
        CLOSE storage_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( storage_cur%ISOPEN ) THEN
        CLOSE storage_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( storage_cur%ISOPEN ) THEN
        CLOSE storage_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( storage_cur%ISOPEN ) THEN
        CLOSE storage_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_target_date  IN  VARCHAR2      --  �p�����[�^�F�����Ώۓ�
    , ov_errbuf       OUT VARCHAR2      --  �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2      --  ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2      --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  ) IS
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
    gn_target_cnt     :=  0;
    gn_normal_cnt     :=  0;
    gn_error_cnt      :=  0;
    gn_warn_cnt       :=  0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �������� (A-1)
    -- ===============================
    init(
        iv_target_date  =>  iv_target_date
      , ov_errbuf       =>  lv_errbuf
      , ov_retcode      =>  lv_retcode
      , ov_errmsg       =>  lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE procedure_common_expt;
    END IF;
    --
    -- ===============================
    -- �Ώۃf�[�^���o����CSV�쐬 (A-2, A-3, A-4)
    -- ===============================
    create_csv(
        ov_errbuf       =>  lv_errbuf
      , ov_retcode      =>  lv_retcode
      , ov_errmsg       =>  lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE procedure_common_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      ov_retcode := lv_retcode;
    END IF;
    --
    -- ===============================
    -- �t�@�C��CLOSE (A-5)
    -- ===============================
    UTL_FILE.FCLOSE( file => g_file_handle );
    --
  EXCEPTION
    WHEN procedure_common_expt THEN
      --  �t�@�C����OPEN���Ă���ꍇ�ACLOSE
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
      --  ���b�Z�[�W�A�X�e�[�^�X��main�ֈ����n��
      ov_errmsg     :=  lv_errmsg;
      ov_errbuf     :=  lv_errbuf;
      ov_retcode    :=  lv_retcode;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      --  �t�@�C����OPEN���Ă���ꍇ�ACLOSE
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      --  �t�@�C����OPEN���Ă���ꍇ�ACLOSE
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      --  �t�@�C����OPEN���Ă���ꍇ�ACLOSE
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
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
      errbuf          OUT VARCHAR2        --  �G���[�E���b�Z�[�W  --# �Œ� #
    , retcode         OUT VARCHAR2        --  ���^�[���E�R�[�h    --# �Œ� #
    , iv_target_date  VARCHAR2            --  �����Ώۓ�
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
    submain(
        iv_target_date    =>  iv_target_date  --  �p�����[�^�F�����Ώۓ�
      , ov_errbuf         =>  lv_errbuf       --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode      --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg       --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_error_cnt  :=  gn_error_cnt + 1;
    END IF;
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
END XXCOI010A06C;
/
