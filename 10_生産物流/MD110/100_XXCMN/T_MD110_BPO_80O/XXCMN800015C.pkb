CREATE OR REPLACE PACKAGE BODY XXCMN800015C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCMN800015C(body)
 * Description      : ���b�g����CSV�t�@�C���o�͂��A���[�N�t���[�`���ŘA�g���܂��B
 * MD.050           : ���b�g���C���^�t�F�[�X<T_MD050_BPO_801>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������                              (B-1)
 *  output_data            �f�[�^�擾�ECSV�o�͏���               (B-2)
 *  submain                ���C�������v���V�[�W��
 *                         �I������                              (B-3)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/08/19    1.0   K.Kiriu          �V�K�쐬
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
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCMN800015C';            -- �p�b�P�[�W��
  -- �V�X�e�����t
  cd_sysdate                  CONSTANT DATE          := SYSDATE;                   -- �V�X�e�����t
  -- �v���t�@�C��
  cv_prof_unit_div            CONSTANT VARCHAR2(22)  := 'XXCMN_800015C_UNIT_DIV';  -- XXCMN:���b�g���C���^�t�F�[�X�P�ʋ敪
  cv_prof_ntf_code            CONSTANT VARCHAR2(22)  := 'XXCMN_800015C_NTF_CODE';  -- XXCMN:���b�g���C���^�t�F�[�X����
  -- ���b�Z�[�W�֘A
  cv_app_xxcmn                CONSTANT VARCHAR2(5)   := 'XXCMN';                   -- �A�v���P�[�V�����Z�k��(���Y:�}�X�^)
  cv_msg_xxcmn_10002          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-10002';         -- �v���t�@�C���擾�G���[
  cv_msg_xxcmn_11048          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11048';         -- �Ώۃf�[�^���擾�G���[
  cv_msg_xxcmn_11049          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11049';         -- ���b�g���C���^�t�F�[�X�p�����[�^
  cv_msg_xxcmn_11050          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11050';         -- �擾�G���[
  cv_msg_xxcmn_11053          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11053';         -- �݌ɏƉ��ʃf�[�^�\�[�X�p�b�P�[�W�G���[
  -- �g�[�N���p���b�Z�[�W
  cv_msg_xxcmn_11051          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11051';         -- OPM�ۊǏꏊ���VIEW
  cv_msg_xxcmn_11052          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11052';         -- OPM�i�ڃ}�X�^
  cv_msg_xxcmn_11054          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11054';         -- OPM�i�ڏ��VIEW
  cv_msg_xxcmn_11056          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11056';         -- OPM���b�g�}�X�^
  --�g�[�N��
  cv_tkn_item_no              CONSTANT VARCHAR2(9)   := 'ITEM_CODE';               -- ���̓p�����[�^�i�i�ڃR�[�h�j
  cv_tkn_item_div             CONSTANT VARCHAR2(8)   := 'ITEM_DIV';                -- ���̓p�����[�^�i�i�ڋ敪�j
  cv_tkn_lot_no               CONSTANT VARCHAR2(8)   := 'LOT_NO';                  -- ���̓p�����[�^�i���b�gNo�j
  cv_tkn_subinv_code          CONSTANT VARCHAR2(11)  := 'SUBINV_CODE';             -- ���̓p�����[�^�i�q�ɃR�[�h�j
  cv_tkn_effective_date       CONSTANT VARCHAR2(14)  := 'EFFECTIVE_DATE';          -- ���̓p�����[�^�i�L�����j
  cv_tkn_prod_div             CONSTANT VARCHAR2(8)   := 'PROD_DIV';                -- ���̓p�����[�^�i���i�敪�j
  cv_tkn_ng_profile           CONSTANT VARCHAR2(10)  := 'NG_PROFILE';              -- �v���t�@�C����
  cv_tkn_table                CONSTANT VARCHAR2(5)   := 'TABLE';                   -- �e�[�u����
  cv_tkn_errmsg               CONSTANT VARCHAR2(6)   := 'ERRMSG';                  -- SQL�G���[
  cv_tkn_item_id              CONSTANT VARCHAR2(7)   := 'ITEM_ID';                 -- �i��ID
  cv_tkn_location_id          CONSTANT VARCHAR2(11)  := 'LOCATION_ID';             -- �q��ID
  cv_tkn_cust_stock_whse      CONSTANT VARCHAR2(15)  := 'CUST_STOCK_WHSE';         -- �����݌ɊǗ��Ώ�
  --�t�H�[�}�b�g
  cv_fmt_date                 CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD';
  cv_fmt_datetime             CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS';
  cv_fmt_datetime2            CONSTANT VARCHAR2(30)  := 'YYYYMMDDHH24MISS';
  -- WF�֘A
  cv_ope_div                  CONSTANT VARCHAR2(2)   := '11';                      -- �����敪:11(���b�g���)
  cv_wf_class                 CONSTANT VARCHAR2(1)   := '6';                       -- �Ώ�:6(�E��)
  -- �o�͍���
  cv_coop_name_itoen          CONSTANT VARCHAR2(5)   := 'ITOEN';                   -- ��Ж�:ITOEN
  cv_data_type                CONSTANT VARCHAR2(3)   := '900';                     -- �f�[�^���:900(���b�g���)
  cv_branch_no                CONSTANT VARCHAR2(2)   := '97';                      -- �`���p�}��:97(���b�g���)
  -- �t�@�C������
  cv_file_mode                CONSTANT VARCHAR2(1)   := 'w';                       -- ���[�h(�㏑)
  -- �i�ڋ敪
  cv_material_g               CONSTANT VARCHAR2(1)   := '1';                       -- ����
  cv_semi_f_item              CONSTANT VARCHAR2(1)   := '4';                       -- �����i
  cv_item                     CONSTANT VARCHAR2(1)   := '5';                       -- ���i
  -- ���̑�
  cv_y                        CONSTANT VARCHAR2(1)   := 'Y';                       -- �t���O:'Y'
  cv_n                        CONSTANT VARCHAR2(1)   := 'N';                       -- �t���O:'N'
  cv_separate_code            CONSTANT VARCHAR2(1)   := ',';                       -- ��؂蕶���i�J���}�j
  cv_extension                CONSTANT VARCHAR2(1)   := '.';                       -- ��؂蕶���i�t�@�C���g���q)
  cv_space                    CONSTANT VARCHAR2(1)   := ' ';                       -- ��؂蕶���i�X�y�[�X)
  cv_underscore               CONSTANT VARCHAR2(1)   := '_';                       -- ��؂蕶���i�A���_�[�X�R�A)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �v���t�@�C���i�[�p
  gv_unit_div           VARCHAR2(10);                                              -- �P�ʋ敪
  gt_ntf_code           fnd_lookup_values.attribute3%TYPE;                         -- ����
  -- �p�����[�^�i�[�p
  gt_item_div           xxcmn_item_categories_v.segment1%TYPE;                     -- �i�ڋ敪
  gt_prod_div           xxcmn_item_categories_v.segment1%TYPE;                     -- ���i�敪
  gt_lot_no             ic_lots_mst.lot_no%TYPE;                                   -- ���b�gNo
  gd_effective_date     DATE;                                                      -- �L����
  -- �}�X�^�擾�p
  gt_item_id            ic_item_mst_b.item_id%TYPE;                                -- �i��ID
  gt_location_id        mtl_item_locations.inventory_location_id%TYPE;             -- ���P�[�V����ID
  gt_cust_stock_whse    ic_whse_mst.attribute1%TYPE;                               -- �����݌ɊǗ��Ώ�
--
  -- ===============================
  -- �J�[�\����`
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (B-1)
   **********************************************************************************/
  PROCEDURE init(
    iv_item_code              IN  VARCHAR2  -- 1.�i�ڃR�[�h
   ,iv_item_div               IN  VARCHAR2  -- 2.�i�ڋ敪
   ,iv_lot_no                 IN  VARCHAR2  -- 3.���b�gNo
   ,iv_subinventory_code      IN  VARCHAR2  -- 4.�q�ɃR�[�h
   ,iv_effective_date         IN  VARCHAR2  -- 5.�L����
   ,iv_prod_div               IN  VARCHAR2  -- 6.���i�敪
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
    lv_tkn_msg  VARCHAR2(100);  -- �G���[���g�[�N���擾�p
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
                  ,iv_name               => cv_msg_xxcmn_11049
                  ,iv_token_name1        => cv_tkn_item_no
                  ,iv_token_value1       => iv_item_code
                  ,iv_token_name2        => cv_tkn_item_div
                  ,iv_token_value2       => iv_item_div
                  ,iv_token_name3        => cv_tkn_lot_no
                  ,iv_token_value3       => iv_lot_no
                  ,iv_token_name4        => cv_tkn_subinv_code
                  ,iv_token_value4       => iv_subinventory_code
                  ,iv_token_name5        => cv_tkn_effective_date
                  ,iv_token_value5       => iv_effective_date
                  ,iv_token_name6        => cv_tkn_prod_div
                  ,iv_token_value6       => iv_prod_div
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
    -- �p�����[�^�i�[
    --==================================
    -- �K�{
    gt_item_div       := iv_item_div;
    gt_prod_div       := iv_prod_div;
    gd_effective_date := TO_DATE( iv_effective_date, cv_fmt_date );
    -- �C��
    IF ( iv_lot_no IS NOT NULL ) THEN
      gt_lot_no       := iv_lot_no;
    ELSE
      gt_lot_no       := NULL;
    END IF;
--
    --==================================
    -- �v���t�@�C���l�擾
    --==================================
    -- XXCMN:���b�g���C���^�t�F�[�X�P�ʋ敪
    gv_unit_div := FND_PROFILE.VALUE( cv_prof_unit_div );
    -- �擾�ł��Ȃ��ꍇ
    IF ( gv_unit_div IS NULL ) THEN
      -- �v���t�@�C���擾�G���[���b�Z�[�W
      lv_errmsg := xxcmn_common_pkg.get_msg(
                      iv_application  => cv_app_xxcmn
                     ,iv_name         => cv_msg_xxcmn_10002
                     ,iv_token_name1  => cv_tkn_ng_profile
                     ,iv_token_value1 => cv_prof_unit_div
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCMN:���b�g���C���^�t�F�[�X����
    gt_ntf_code := FND_PROFILE.VALUE( cv_prof_ntf_code );
    -- �擾�ł��Ȃ��ꍇ
    IF ( gt_ntf_code IS NULL ) THEN
      -- �v���t�@�C���擾�G���[���b�Z�[�W
      lv_errmsg := xxcmn_common_pkg.get_msg(
                      iv_application  => cv_app_xxcmn
                     ,iv_name         => cv_msg_xxcmn_10002
                     ,iv_token_name1  => cv_tkn_ng_profile
                     ,iv_token_value1 => cv_prof_ntf_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �e�}�X�^�����擾
    --==================================
    -- OPM�ۊǏꏊ���VIEW
    BEGIN
      SELECT  xilv.inventory_location_id  inventory_location_id  -- �q��ID
             ,xilv.customer_stock_whse    customer_stock_whse    -- �����݌ɊǗ��Ώ�
      INTO    gt_location_id
             ,gt_cust_stock_whse
      FROM    xxcmn_item_locations_v xilv
      WHERE   xilv.segment1 = iv_subinventory_code
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �g�[�N���̎擾(�e�[�u����)
        lv_tkn_msg := xxcmn_common_pkg.get_msg(
                         iv_application  => cv_app_xxcmn
                        ,iv_name         => cv_msg_xxcmn_11051
                      );
        -- ���b�Z�[�W����
        lv_errmsg := xxcmn_common_pkg.get_msg(
                        iv_application  => cv_app_xxcmn
                       ,iv_name         => cv_msg_xxcmn_11050
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => lv_tkn_msg
                       ,iv_token_name2  => cv_tkn_errmsg
                       ,iv_token_value2 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- �p�����[�^�i�ڃR�[�h��NULL�ł͂Ȃ��ꍇ�̂�
    IF ( iv_item_code IS NOT NULL ) THEN
      -- OPM�i�ڃ}�X�^
      BEGIN
        SELECT  iim.item_id  item_id  --�i��ID
        INTO    gt_item_id
        FROM    ic_item_mst_b iim
        WHERE   iim.item_no = iv_item_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- �g�[�N���̎擾(�e�[�u����)
          lv_tkn_msg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_app_xxcmn
                          ,iv_name         => cv_msg_xxcmn_11052
                        );
          -- ���b�Z�[�W����
          lv_errmsg := xxcmn_common_pkg.get_msg(
                          iv_application  => cv_app_xxcmn
                         ,iv_name         => cv_msg_xxcmn_11050
                         ,iv_token_name1  => cv_tkn_table
                         ,iv_token_value1 => lv_tkn_msg
                         ,iv_token_name2  => cv_tkn_errmsg
                         ,iv_token_value2 => SQLERRM
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
    ELSE
      gt_item_id := NULL;
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
   * Description      : CSV�o�͏��� (B-2)
   **********************************************************************************/
  PROCEDURE output_data(
    ov_errbuf                 OUT VARCHAR2  -- �G���[�E���b�Z�[�W                  --# �Œ� #
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
    cn_default_lot_id   CONSTANT NUMBER       := 0;      -- �f�t�H���g���b�gID
    cv_default_lot_no   CONSTANT VARCHAR2(1)  := '0';    -- �f�t�H���g���b�g���̃��b�gNo
    cv_num_of_0         CONSTANT VARCHAR2(1)  := '0';    -- �����i�����̒l��NULL�̏ꍇ)
--
    -- *** ���[�J���ϐ� ***
    lr_wf_whs_rec       xxwsh_common3_pkg.wf_whs_rec;     -- �t�@�C�����i�[���R�[�h
    lf_file_hand        UTL_FILE.FILE_TYPE;               -- �t�@�C���E�n���h��
    lv_save_file_name   VARCHAR2(150);                    -- �t�@�C����(�ʒm��ێ��p)
    lv_csv_data         VARCHAR2(1000);                   -- CSV������
    lt_item_no_before   ic_item_mst_b.item_no%TYPE;       -- �i�ڃR�[�h(�u���[�N����p)
    lt_item_um          ic_item_mst_b.item_um%TYPE;       -- �P�ʖ���
    lt_frequent_qty     ic_item_mst_b.attribute17%TYPE;   -- ��\����
    lv_tkn_msg          VARCHAR2(100);                    -- �G���[���g�[�N���擾�p
    lt_lot_no           ic_lots_mst.lot_no%TYPE;          -- ���b�gNo
    lt_num_of_lot       ic_lots_mst.attribute6%TYPE;      -- ���b�g�}�X�^�݌ɓ���
    lt_num_of_item      ic_item_mst_b.attribute11%TYPE;   -- �i�ڃ}�X�^�P�[�X����
    lv_num_of_case      VARCHAR2(240);                    -- �����iCSV�ݒ�p�j
--
    -- *** ���[�J���e�[�u���^ ***
    l_ilm_block_tab     xxinv540001.tbl_ilm_block;        --���ʊi�[�p�z��
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
--
    --==================================
    -- ���[�N�t���[���̎擾
    --==================================
    -- ���ʊ֐��u�A�E�g�o�E���h�����擾�֐��v�ďo
    xxwsh_common3_pkg.get_wsh_wf_info(
      iv_wf_ope_div       => cv_ope_div     -- �����敪
     ,iv_wf_class         => cv_wf_class    -- �Ώ�
     ,iv_wf_notification  => gt_ntf_code    -- ����
     ,or_wf_whs_rec       => lr_wf_whs_rec  -- �t�@�C�����
     ,ov_errbuf           => lv_errbuf      -- �G���[�E���b�Z�[�W
     ,ov_retcode          => lv_retcode     -- ���^�[���E�R�[�h
     ,ov_errmsg           => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- WF�I�[�i�[���N�����[�U�֕ύX
    lr_wf_whs_rec.wf_owner := fnd_global.user_name;
--
    -- �t�@�C������ύX����( �t�@�C����_YYYYMMDDHH24MISS.csv)
    lv_save_file_name := SUBSTRB( lr_wf_whs_rec.file_name, 1, INSTRB( lr_wf_whs_rec.file_name, cv_extension ) -1 ) ||
                         cv_underscore                                                                             ||
                         TO_CHAR( cd_sysdate, cv_fmt_datetime2 )                                                   ||
                         SUBSTRB( lr_wf_whs_rec.file_name, INSTRB( lr_wf_whs_rec.file_name, cv_extension ) )
                         ;
--
    --==================================
    -- �t�@�C���I�[�v��
    --==================================
    lf_file_hand := UTL_FILE.FOPEN(
                       lr_wf_whs_rec.directory -- �f�B���N�g��
                      ,lv_save_file_name        -- �t�@�C����
                      ,cv_file_mode            -- ���[�h�i�㏑�j
                    );
--
    --==================================
    -- ���b�g�����擾
    --==================================
    BEGIN
      -- �݌ɏƉ��ʃf�[�^�\�[�X�p�b�P�[�W�u�f�[�^�擾�֐��v�ďo
      xxinv540001.blk_ilm_qry(
         ior_ilm_data             =>  l_ilm_block_tab     -- ���ʊi�[�p�z��  tbl_ilm_block I/O
        ,in_item_id               =>  gt_item_id          -- �i��ID          xxcmn_item_mst_v.item_id%TYPE
        ,iv_parent_div            =>  cv_n                -- �e�R�[�h�敪    VARCHAR2
        ,in_inventory_location_id =>  gt_location_id      -- �ۊǑq��ID      xxcmn_item_locations_v.inventory_location_id%TYPE
        ,iv_deleg_house           =>  cv_n                -- ��\�q�ɏƉ�    VARCHAR2
        ,iv_ext_warehouse         =>  cv_n                -- �q�ɒ��o�t���O  VARCHAR2
        ,iv_item_div_code         =>  gt_item_div         -- �i�ڋ敪�R�[�h  xxcmn_item_categories_v.segment1%TYPE
        ,iv_prod_div_code         =>  gt_prod_div         -- ���i�敪�R�[�h  xxcmn_item_categories_v.segment1%TYPE
        ,iv_unit_div              =>  gv_unit_div         -- �P�ʋ敪        VARCHAR2
        ,iv_qt_status_code        =>  NULL                -- �i�����茋��    xxwip_qt_inspection.qt_effect1%TYPE
        ,id_manu_date_from        =>  NULL                -- �����N����From  DATE
        ,id_manu_date_to          =>  NULL                -- �����N����To    DATE
        ,iv_prop_sign             =>  NULL                -- �ŗL�L��        ic_lots_mst.attribute2%TYPE
        ,id_consume_from          =>  NULL                -- �ܖ�����From    DATE
        ,id_consume_to            =>  NULL                -- �ܖ�����To      DATE
        ,iv_lot_no                =>  gt_lot_no           -- ���b�g��        ic_lots_mst.lot_no%TYPE
        ,iv_register_code         =>  gt_cust_stock_whse  -- ���`�R�[�h      xxcmn_item_locations_v.customer_stock_whse%TYPE,
        ,id_effective_date        =>  gd_effective_date   -- �L�����t        DATE
        ,iv_ext_show              =>  cv_y                -- �݌ɗL�����\��  VARCHAR2
      );
    EXCEPTION
      WHEN OTHERS THEN
        -- �݌ɏƉ��ʃf�[�^�\�[�X�p�b�P�[�W�G���[���b�Z�[�W
        lv_errmsg := xxcmn_common_pkg.get_msg(
                        iv_application  => cv_app_xxcmn
                       ,iv_name         => cv_msg_xxcmn_11053
                       ,iv_token_name1  => cv_tkn_item_id
                       ,iv_token_value1 => TO_CHAR( gt_item_id )
                       ,iv_token_name2  => cv_tkn_location_id
                       ,iv_token_value2 => TO_CHAR( gt_location_id )
                       ,iv_token_name3  => cv_tkn_cust_stock_whse
                       ,iv_token_value3 => gt_cust_stock_whse
                       ,iv_token_name4  => cv_tkn_errmsg
                       ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- �Ώی����J�E���g
    gn_target_cnt := l_ilm_block_tab.COUNT;
--
    --==================================
    -- CSV�o�͏���
    --==================================
    << csv_loop >>
    FOR i IN 1..gn_target_cnt LOOP
--
      -- �����\���A�莝�݌ɐ��A���ɗ\�萔�A�o�ɗ\�萔�̂����ꂩ��0�ȊO�̂ݏ�������
      IF (
           ( l_ilm_block_tab(i).subtractable <> 0 )
           OR
           ( l_ilm_block_tab(i).inv_stock_vol <> 0 )
           OR
           ( l_ilm_block_tab(i).supply_stock_plan <> 0 )
           OR
           ( l_ilm_block_tab(i).take_stock_plan <> 0 )
         )
      THEN
--
        -- ������
        lv_num_of_case := NULL;
--
        -- �p�����[�^�i�ڋ敪���A�����E�����i�E���i�̏ꍇ
        IF ( gt_item_div IN ( cv_material_g, cv_semi_f_item, cv_item ) ) THEN
--
          -- ������
          lt_num_of_lot := NULL;
--
          --==================================
          -- ���b�g�}�X�^�̍݌ɓ����擾
          --==================================
          BEGIN
            SELECT NVL( ilm.attribute6, cv_num_of_0 )  num_of_case
            INTO   lt_num_of_lot
            FROM   ic_lots_mst    ilm
            WHERE  ilm.lot_id = l_ilm_block_tab(i).ilm_lot_id
            ;
          EXCEPTION
            WHEN OTHERS THEN
              -- �g�[�N���̎擾(�e�[�u����)
              lv_tkn_msg := xxcmn_common_pkg.get_msg(
                               iv_application  => cv_app_xxcmn
                              ,iv_name         => cv_msg_xxcmn_11056
                            );
              -- ���b�Z�[�W����
              lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => cv_app_xxcmn
                             ,iv_name         => cv_msg_xxcmn_11050
                             ,iv_token_name1  => cv_tkn_table
                             ,iv_token_value1 => lv_tkn_msg
                             ,iv_token_name2  => cv_tkn_errmsg
                             ,iv_token_value2 => SQLERRM
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
          END;
        END IF;
--
        -- ���[�v����A�������́A�O�o�͑Ώۃ��R�[�h�ƕi�ڂ��قȂ�ꍇ�̂�
        IF (
             ( lt_item_no_before IS NULL )
             OR
             ( lt_item_no_before <> l_ilm_block_tab(i).ximv_item_no )
           )
        THEN
--
          -- ������
          lt_item_um      := NULL;
          lt_frequent_qty := NULL;
          lt_num_of_item  := NULL;
--
          --==================================
          -- �P�ʖ��́E��\�����擾
          --==================================
          BEGIN
            SELECT /*+
                     USE_NL( ximv.iimb ximv.ximb ximv.msib )
                   */
                   ximv.item_um                            item_um       -- �P�ʖ�
                  ,ximv.frequent_qty                       frequent_qty  -- ��\����
                  ,NVL( ximv.num_of_cases, cv_num_of_0 )   num_of_item   -- �P�[�X����
            INTO   lt_item_um
                  ,lt_frequent_qty
                  ,lt_num_of_item
            FROM   xxcmn_item_mst_v ximv
            WHERE  ximv.item_no      = l_ilm_block_tab(i).ximv_item_no
            ;
          EXCEPTION
            WHEN OTHERS THEN
              -- �g�[�N���̎擾(�e�[�u����)
              lv_tkn_msg := xxcmn_common_pkg.get_msg(
                               iv_application  => cv_app_xxcmn
                              ,iv_name         => cv_msg_xxcmn_11054
                            );
              -- ���b�Z�[�W����
              lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => cv_app_xxcmn
                             ,iv_name         => cv_msg_xxcmn_11050
                             ,iv_token_name1  => cv_tkn_table
                             ,iv_token_value1 => lv_tkn_msg
                             ,iv_token_name2  => cv_tkn_errmsg
                             ,iv_token_value2 => SQLERRM
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
          END;
--
        END IF;
--
        --==================================
        -- ���b�gNo�̕ҏW
        --==================================
        -- ���b�g������i�f�t�H���g���b�g�ȊO�j�̏ꍇ
        IF ( l_ilm_block_tab(i).ilm_lot_id <> cn_default_lot_id ) THEN
          lt_lot_no := l_ilm_block_tab(i).ilm_lot_no;  -- �擾�������b�gNo
        -- ���b�g���Ȃ��i�f�t�H���g���b�g�j�̏ꍇ
        ELSE
          lt_lot_no := cv_default_lot_no;              -- �f�t�H���g���b�g�p�̃��b�gNo�Œ�l
        END IF;
--
        --==================================
        -- �����̕ҏW
        --==================================
        -- �p�����[�^�i�ڋ敪���A�����E�����i�E���i�̏ꍇ
        IF ( gt_item_div IN ( cv_material_g, cv_semi_f_item, cv_item ) ) THEN
          -- �擾�������b�g�̓�����0�ANULL�ȊO�̏ꍇ
          IF ( lt_num_of_lot <> cv_num_of_0 ) THEN
            lv_num_of_case := lt_num_of_lot;    -- ���b�g�}�X�^�̍݌ɓ���
          -- �擾�������b�g�̓�����0�ANULL�̏ꍇ
          ELSE
            lv_num_of_case := lt_frequent_qty;  -- �i�ڃ}�X�^�̑�\����(NULL�̏ꍇ��NULL)
          END IF;
        -- �p�����[�^�i�ڋ敪���A���ނ̏ꍇ
        ELSE
          -- �擾�����i�ڂ̓�����0�ANULL�ȊO�̏ꍇ
          IF (  lt_num_of_item <> cv_num_of_0 ) THEN
            lv_num_of_case := lt_num_of_item;   -- �i�ڃ}�X�^�̃P�[�X����
          ELSE
            lv_num_of_case := lt_frequent_qty;  -- �i�ڃ}�X�^�̑�\����(NULL�̏ꍇ��NULL)
          END IF;
        END IF;
--
        --==================================
        -- CSV�o�͍��ڂ̕ҏW
        --==================================
        lv_csv_data := cv_coop_name_itoen                                                   || cv_separate_code || -- 1.��Ж�
                       cv_data_type                                                         || cv_separate_code || -- 2.�f�[�^���
                       cv_branch_no                                                         || cv_separate_code || -- 3.�`���p�}��
                       l_ilm_block_tab(i).ximv_item_no                                      || cv_separate_code || -- 4.����1
                       lt_lot_no                                                            || cv_separate_code || -- 5.����2
                       NULL                                                                 || cv_separate_code || -- 6.����3
                       l_ilm_block_tab(i).xlvv_xl8_meaning                                  || cv_separate_code || -- 7.����1
                       NULL                                                                 || cv_separate_code || -- 8.����2
                       NULL                                                                 || cv_separate_code || -- 9.����3
                       l_ilm_block_tab(i).xlvv_xl7_meaning                                  || cv_separate_code || -- 10.���1
                       lv_num_of_case                                                       || cv_separate_code || -- 11.���2
                       TO_CHAR( l_ilm_block_tab(i).ilm_attribute1, cv_fmt_date )            || cv_separate_code || -- 12.���3
                       l_ilm_block_tab(i).ilm_attribute2                                    || cv_separate_code || -- 13.���4
                       TO_CHAR( l_ilm_block_tab(i).ilm_attribute3, cv_fmt_date )            || cv_separate_code || -- 14.���5
                       NULL                                                                 || cv_separate_code || -- 15.���6
                       NULL                                                                 || cv_separate_code || -- 16.���7
                       NULL                                                                 || cv_separate_code || -- 17.���8
                       NULL                                                                 || cv_separate_code || -- 18.���9
                       l_ilm_block_tab(i).ilm_attribute12                                   || cv_separate_code || -- 19.���10
                       lt_item_um                                                           || cv_separate_code || -- 20.���11
                       NULL                                                                 || cv_separate_code || -- 21.���12
                       NULL                                                                 || cv_separate_code || -- 22.���13
                       NULL                                                                 || cv_separate_code || -- 23.���14
                       NULL                                                                 || cv_separate_code || -- 24.���15
                       NULL                                                                 || cv_separate_code || -- 25.���16
                       NULL                                                                 || cv_separate_code || -- 26.���17
                       NULL                                                                 || cv_separate_code || -- 27.���18
                       NULL                                                                 || cv_separate_code || -- 28.���19
                       NULL                                                                 || cv_separate_code || -- 29.���20
                       l_ilm_block_tab(i).ilm_attribute13                                   || cv_separate_code || -- 30.�敪1
                       NULL                                                                 || cv_separate_code || -- 31.�敪2
                       NULL                                                                 || cv_separate_code || -- 32.�敪3
                       NULL                                                                 || cv_separate_code || -- 33.�敪4
                       NULL                                                                 || cv_separate_code || -- 34.�敪5
                       NULL                                                                 || cv_separate_code || -- 35.�敪6
                       NULL                                                                 || cv_separate_code || -- 36.�敪7
                       NULL                                                                 || cv_separate_code || -- 37.�敪8
                       NULL                                                                 || cv_separate_code || -- 38.�敪9
                       NULL                                                                 || cv_separate_code || -- 39.�敪10
                       NULL                                                                 || cv_separate_code || -- 40.�敪11
                       NULL                                                                 || cv_separate_code || -- 41.�敪12
                       NULL                                                                 || cv_separate_code || -- 42.�敪13
                       NULL                                                                 || cv_separate_code || -- 43.�敪14
                       NULL                                                                 || cv_separate_code || -- 44.�敪15
                       NULL                                                                 || cv_separate_code || -- 45.�敪16
                       NULL                                                                 || cv_separate_code || -- 46.�敪17
                       NULL                                                                 || cv_separate_code || -- 47.�敪18
                       NULL                                                                 || cv_separate_code || -- 48.�敪19
                       NULL                                                                 || cv_separate_code || -- 49.�敪20
                       TO_CHAR( l_ilm_block_tab(i).ilm_creation_date, cv_fmt_date )         || cv_separate_code || -- 50.�K�p�J�n��
                       TO_CHAR( l_ilm_block_tab(i).ilm_last_update_date, cv_fmt_datetime )                         -- 51.�X�V����
        ;
--
        --==================================
        -- �t�@�C���o��
        --==================================
        UTL_FILE.PUT_LINE(
          lf_file_hand
         ,lv_csv_data
        );
--
        -- �i�ڃu���[�N�p�̕ϐ��Ɍ����R�[�h�̒l���i�[
        lt_item_no_before := l_ilm_block_tab(i).ximv_item_no;
        -- ���������J�E���g
        gn_normal_cnt     := gn_normal_cnt + 1;
--
      END IF;
--
    END LOOP csv_loop;
--
    --==================================
    -- �t�@�C���N���[�Y
    --==================================
    UTL_FILE.FCLOSE( lf_file_hand );
--
    -- ����������0���ȊO(�o�͑Ώۂ���)�̏ꍇ
    IF ( gn_normal_cnt <> 0 ) THEN
      --==================================
      -- ���[�N�t���[�ʒm
      --==================================
      xxwsh_common3_pkg.wf_whs_start(
        ir_wf_whs_rec => lr_wf_whs_rec            -- ���[�N�t���[�֘A���
       ,iv_filename   => lv_save_file_name        -- �t�@�C����
       ,ov_errbuf     => lv_errbuf                -- �G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode               -- ���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    -- ����������0��(�o�͑ΏۂȂ�)�̏ꍇ
    ELSE
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
      -- �t�@�C�����I�[�v�����Ă���ꍇ
      IF ( UTL_FILE.IS_OPEN( lf_file_hand ) ) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �t�@�C�����I�[�v�����Ă���ꍇ
      IF ( UTL_FILE.IS_OPEN( lf_file_hand ) ) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
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
    iv_item_code              IN  VARCHAR2  -- 1.�i�ڃR�[�h
   ,iv_item_div               IN  VARCHAR2  -- 2.�i�ڋ敪
   ,iv_lot_no                 IN  VARCHAR2  -- 3.���b�gNo
   ,iv_subinventory_code      IN  VARCHAR2  -- 4.�q�ɃR�[�h
   ,iv_effective_date         IN  VARCHAR2  -- 5.�L����
   ,iv_prod_div               IN  VARCHAR2  -- 6.���i�敪
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
      iv_item_code          =>  iv_item_code         -- 1.�i�ڃR�[�h
     ,iv_item_div           =>  iv_item_div          -- 2.�i�ڋ敪
     ,iv_lot_no             =>  iv_lot_no            -- 3.���b�gNo
     ,iv_subinventory_code  =>  iv_subinventory_code -- 4.�q�ɃR�[�h
     ,iv_effective_date     =>  iv_effective_date    -- 5.�L����
     ,iv_prod_div           =>  iv_prod_div          -- 6.���i�敪
     ,ov_errbuf             =>  lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            =>  lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             =>  lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
      ov_errbuf               =>  lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
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
   ,iv_item_code              IN  VARCHAR2        -- 1.�i�ڃR�[�h
   ,iv_item_div               IN  VARCHAR2        -- 2.�i�ڋ敪
   ,iv_lot_no                 IN  VARCHAR2        -- 3.���b�gNo
   ,iv_subinventory_code      IN  VARCHAR2        -- 4.�q�ɃR�[�h
   ,iv_effective_date         IN  VARCHAR2        -- 5.�L����
   ,iv_prod_div               IN  VARCHAR2        -- 6.���i�敪
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
      iv_item_code          =>  iv_item_code          -- 1.�i�ڃR�[�h
     ,iv_item_div           =>  iv_item_div           -- 2.�i�ڋ敪
     ,iv_lot_no             =>  iv_lot_no             -- 3.���b�gNo
     ,iv_subinventory_code  =>  iv_subinventory_code  -- 4.�q�ɃR�[�h
     ,iv_effective_date     =>  iv_effective_date     -- 5.�L����
     ,iv_prod_div           =>  iv_prod_div           -- 6.���i�敪
     ,ov_errbuf             =>  lv_errbuf             -- �G���[�E���b�Z�[�W             --# �Œ� #
     ,ov_retcode            =>  lv_retcode            -- ���^�[���E�R�[�h               --# �Œ� #
     ,ov_errmsg             =>  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
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
      gn_normal_cnt := 0; -- ��������
      gn_error_cnt  := 0; -- �G���[����
    ELSE
    -- �X�e�[�^�X������̏ꍇ
      -- �����ݒ�
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
END XXCMN800015C;
/
