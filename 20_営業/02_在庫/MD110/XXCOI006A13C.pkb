CREATE OR REPLACE PACKAGE BODY XXCOI006A13C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A13C(body)
 * Description      : �I�����Ճf�[�^�쐬
 * MD.050           : �I�����Ճf�[�^�쐬 <MD050_COI_A13>
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  chk_mst_data           �}�X�^�`�F�b�N(A-3)
 *  get_disposition_id     ����Ȗڕʖ�ID�擾(A-4)
 *  ins_tran_interface     ���ގ��OIF�o��(A-5)
 *  upd_inv_control        �I���Ǘ��X�V(A-6)
 *  submain                ���C�������v���V�[�W��
 *                         �I�����Տ�񒊏o(A-2)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������(A-7)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/27    1.0   N.Abe            �V�K�쐬
 *  2009/05/08    1.1   T.Nakamura       [T1_0782]�ُ�I�����ɐ���������0�Ƃ���悤�C��
 *  2009/06/03    1.2   H.Sasaki         [T1_1202]�ۊǏꏊ�}�X�^�̌��������ɍ݌ɑg�DID��ǉ�
 *  2009/06/26    1.3   H.Sasaki         [0000258]�I���ΏۊO�������ΏۂƂ���
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
  org_code_expt            EXCEPTION;     -- �݌ɑg�D�R�[�h�擾�G���[
  org_id_expt              EXCEPTION;     -- �݌ɑg�DID�擾�G���[
  lock_expt                EXCEPTION;     -- ���b�N�擾�G���[
  chk_item_expt            EXCEPTION;     -- �i�ڃX�e�[�^�X�L���`�F�b�N�G���[
  chk_sales_item_expt      EXCEPTION;     -- �i�ڔ���Ώۋ敪�L���`�F�b�N�G���[
  genmou_son_expt          EXCEPTION;     -- �I�����Ց�����^�C�v���擾�G���[
  genmou_eki_expt          EXCEPTION;     -- �I�����Չv����^�C�v���擾�G���[
  tran_id_expt             EXCEPTION;     -- ����^�C�v�擾�G���[
  dispo_id_expt            EXCEPTION;     -- ����Ȗڕʖ�ID�擾�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCOI006A13C'; -- �p�b�P�[�W��
--
  cv_xxcoi_short_name CONSTANT VARCHAR2(10)  := 'XXCOI';        -- �A�h�I���F�̕��E�݌ɗ̈�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    on_organization_id  OUT NUMBER,                                         -- 1.�݌ɑg�DID
    ov_period_date      OUT VARCHAR2,                                       -- 2.��v����
    ot_tran_id_son      OUT mtl_transaction_types.transaction_type_id%TYPE, -- 3.���ID�i�I�����Ց��j
    ot_tran_id_eki      OUT mtl_transaction_types.transaction_type_id%TYPE, -- 4.���ID�i�I�����Չv�j
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'init';             -- �v���O������
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
    --���b�Z�[�W�ԍ�
    cv_xxcoi1_msg_00023   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00023';  --�R���J�����g�p�����[�^�Ȃ�
    cv_xxcoi1_msg_00005   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00005';  --�݌ɑg�D�R�[�h�擾�G���[
    cv_xxcoi1_msg_00006   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00006';  --�݌ɑg�DID�擾�G���[
    cv_xxcoi1_msg_10301   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10301';  --�I�����Ց�����^�C�v���擾�G���[
    cv_xxcoi1_msg_10302   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10302';  --�I�����Չv����^�C�v���擾�G���[
    cv_xxcoi1_msg_00012   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00012';  --����^�C�v�擾�G���[
    --�g�[�N��
    cv_tkn_pro            CONSTANT  VARCHAR2(7)   := 'PRO_TOK';
    cv_tkn_org_code       CONSTANT  VARCHAR2(12)  := 'ORG_CODE_TOK';
    cv_tkn_tran_type      CONSTANT  VARCHAR2(20)  := 'TRANSACTION_TYPE_TOK';
    --�v���t�@�C��
    cv_prf_org_code       CONSTANT  VARCHAR2(24)  := 'XXCOI1_ORGANIZATION_CODE';    --�݌ɑg�D�R�[�h
    cv_prf_genmou_son     CONSTANT  VARCHAR2(27)  := 'XXCOI1_TRAN_NAME_GENMOU_SON'; --�I�����Ց�����^�C�v��
    cv_prf_genmou_eki     CONSTANT  VARCHAR2(27)  := 'XXCOI1_TRAN_NAME_GENMOU_EKI'; --�I�����Չv����^�C�v��
--
    cv_ym                 CONSTANT  VARCHAR2(6)   := 'YYYYMM';
    cv_y                  CONSTANT  VARCHAR2(1)   := 'Y';
    -- *** ���[�J���ϐ� ***
    lv_organization_code  VARCHAR2(4);                                      --�݌ɑg�D�R�[�h
    ln_organization_id    NUMBER;                                           --�݌ɑg�DID
    lt_tran_son           mtl_transaction_types.transaction_type_name%TYPE; --�I�����Ց�����^�C�v��
    lt_tran_eki           mtl_transaction_types.transaction_type_name%TYPE; --�I�����Չv����^�C�v��
    lt_tran_name          mtl_transaction_types.transaction_type_name%TYPE; --�G���[����^�C�v��
    lt_tran_id_son        mtl_transaction_types.transaction_type_id%TYPE;   --�I�����Ց�����^�C�vID
    lt_tran_id_eki        mtl_transaction_types.transaction_type_id%TYPE;   --�I�����Չv����^�C�vID
--
    -- *** ���[�J���E�J�[�\�� ***
    --�݌ɉ�v���Ԏ擾
    CURSOR get_period_date_cur(in_organization_id IN NUMBER)
    IS
      SELECT   TO_CHAR(gp.period_start_date, cv_ym) period_date --�J�n��
      FROM     org_acct_periods gp                              --�݌ɉ�v���ԃe�[�u��
      WHERE    gp.organization_id = in_organization_id
      AND      gp.open_flag       = cv_y                        --�I�[�v���t���O'Y'
      ORDER BY gp.period_start_date
      ;
--
    -- *** ���[�J���E���R�[�h ***
    get_period_date_rec get_period_date_cur%ROWTYPE;
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
    --====================
    --1.���̓p�����[�^�o��
    --====================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_xxcoi1_msg_00023
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --====================================
    --2.�v���t�@�C������݌ɑg�D�R�[�h���擾
    --====================================
    lv_organization_code := fnd_profile.value(cv_prf_org_code);
--
    IF (lv_organization_code IS NULL) THEN
      RAISE org_code_expt;
    END IF;
--
    --====================================
    --3.�݌ɑg�D�R�[�h����݌ɑg�DID���擾
    --====================================
    ln_organization_id := xxcoi_common_pkg.get_organization_id(lv_organization_code);
--
    IF (ln_organization_id IS NULL) THEN
      RAISE org_id_expt;
    END IF;
--
    --====================================
    --4.�I�[�v���݌ɉ�v���Ԏ擾
    --====================================
    OPEN get_period_date_cur(
            in_organization_id  => ln_organization_id);
    FETCH get_period_date_cur INTO get_period_date_rec;
    CLOSE get_period_date_cur;
--
    --====================================
    --5.WHO��擾
    --====================================
    --�ϐ��錾���Ƀf�t�H���g�Ŏ擾
--
    --====================================
    --6.����^�C�v���擾
    --====================================
    --�I�����Ց�
    lt_tran_son := FND_PROFILE.VALUE(cv_prf_genmou_son);
--
    IF (lt_tran_son IS NULL) THEN
      RAISE genmou_son_expt;
    END IF;
    --�I�����Չv
    lt_tran_eki := FND_PROFILE.VALUE(cv_prf_genmou_eki);
--
    IF (lt_tran_eki IS NULL) THEN
      RAISE genmou_eki_expt;
    END IF;
--
    --====================================
    --7.����^�C�vID�擾
    --====================================
    --�I�����Ց�
    lt_tran_id_son  :=  xxcoi_common_pkg.get_transaction_type_id(lt_tran_son);
--
    IF (lt_tran_id_son IS NULL) THEN
      lt_tran_name := lt_tran_son;
      RAISE tran_id_expt;
    END IF;
--
    --�I�����Չv
    lt_tran_id_eki  :=  xxcoi_common_pkg.get_transaction_type_id(lt_tran_eki);
--
    IF (lt_tran_id_eki IS NULL) THEN
      lt_tran_name := lt_tran_eki;
      RAISE tran_id_expt;
    END IF;
--
    --OUT�p�����[�^�ɐݒ�
    on_organization_id := ln_organization_id;
    ov_period_date     := get_period_date_rec.period_date;
    ot_tran_id_son     := lt_tran_id_son;
    ot_tran_id_eki     := lt_tran_id_eki;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** �݌ɑg�D�R�[�h�擾�G���[ ***
    WHEN org_code_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_00005
                 ,iv_token_name1  => cv_tkn_pro
                 ,iv_token_value1 => cv_prf_org_code
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
    --*** �݌ɑg�DID�擾�G���[ ***
    WHEN org_id_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_00006
                 ,iv_token_name1  => cv_tkn_org_code
                 ,iv_token_value1 => lv_organization_code
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
    --*** �I�����Ց�����^�C�v���擾�G���[ ***
    WHEN genmou_son_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10301
                 ,iv_token_name1  => cv_tkn_pro
                 ,iv_token_value1 => cv_prf_genmou_son
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
    --*** �I�����Չv����^�C�v���擾�G���[ ***
    WHEN genmou_eki_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10302
                 ,iv_token_name1  => cv_tkn_pro
                 ,iv_token_value1 => cv_prf_genmou_eki
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
    --*** ����^�C�v�擾�G���[ ***
    WHEN tran_id_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_00012
                 ,iv_token_name1  => cv_tkn_tran_type
                 ,iv_token_value1 => lt_tran_name
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
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
   * Procedure Name   : chk_mst_data
   * Description      : �}�X�^�`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE chk_mst_data(
    it_inventory_item_id  IN  mtl_system_items_b.inventory_item_id%TYPE,          -- 1.�i��ID
    in_organization_id    IN  NUMBER,                                             -- 2.�݌ɑg�DID
    ov_primary_unit       OUT VARCHAR2,                                           -- 3.��P��
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W               --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h                 --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W     --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_mst_data'; -- �v���O������
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
    --���b�Z�[�W
    cv_xxcoi1_msg_10291   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10291';  --�i�ڃX�e�[�^�X�L���G���[
    cv_xxcoi1_msg_10229   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10229';  --�i�ڔ���Ώۋ敪�G���[
    --�g�[�N��
    cv_tkn_item_code      CONSTANT VARCHAR2(9)  := 'ITEM_CODE';
    --�R�[�h���t���O
    cv_inactive           CONSTANT VARCHAR2(8)  := 'Inactive';
    cv_n                  CONSTANT VARCHAR2(1)  := 'N';
    cv_1                  CONSTANT VARCHAR2(1)  := '1';
    cv_2                  CONSTANT VARCHAR2(1)  := '2';
--
    -- *** ���[�J���ϐ� ***
--
    --�i�ڏ��擾�p
    lt_item_code          mtl_system_items_b.segment1%TYPE;                       --�i�ڃR�[�h
    lt_item_status        mtl_system_items_b.inventory_item_status_code%TYPE;     --�i�ڃX�e�[�^�X
    lt_cust_order_flg     mtl_system_items_b.customer_order_enabled_flag%TYPE;    --�ڋq�󒍉\�t���O
    lt_transaction_enable mtl_system_items_b.mtl_transactions_enabled_flag%TYPE;  --����\
    lt_stock_enabled_flg  mtl_system_items_b.stock_enabled_flag%TYPE;             --�݌ɕۗL�\�t���O
    lt_return_enable      mtl_system_items_b.returnable_flag%TYPE;                --�ԕi�\
    lt_sales_class        ic_item_mst_b.attribute26%TYPE;                         --����Ώۋ敪
    lt_primary_unit       mtl_system_items_b.primary_unit_of_measure%TYPE;        --��P��
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
    --=============================
    --1.�i�ڃR�[�h�擾
    --=============================
    BEGIN
      SELECT  msib.segment1
      INTO    lt_item_code
      FROM    mtl_system_items_b  msib
      WHERE   msib.organization_id    = in_organization_id
      AND     msib.inventory_item_id  = it_inventory_item_id
      AND     ROWNUM = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_item_code := NULL;
    END;
--
    --=============================
    --2.�i�ڃX�e�[�^�X�擾
    --=============================
    xxcoi_common_pkg.get_item_info(
          iv_item_code            =>  lt_item_code          -- 1 .�i�ڃR�[�h
         ,in_org_id               =>  in_organization_id    -- 2 .�݌ɑg�DID
         ,ov_item_status          =>  lt_item_status        -- 3 .�i�ڃX�e�[�^�X
         ,ov_cust_order_flg       =>  lt_cust_order_flg     -- 4 .�ڋq�󒍉\�t���O
         ,ov_transaction_enable   =>  lt_transaction_enable -- 5 .����\
         ,ov_stock_enabled_flg    =>  lt_stock_enabled_flg  -- 6 .�݌ɕۗL�\�t���O
         ,ov_return_enable        =>  lt_return_enable      -- 7 .�ԕi�\
         ,ov_sales_class          =>  lt_sales_class        -- 8 .����Ώۋ敪
         ,ov_primary_unit         =>  lt_primary_unit       -- 9 .��P��
         ,ov_errbuf               =>  lv_errbuf             -- 10.�G���[���b�Z�[�W
         ,ov_retcode              =>  lv_retcode            -- 11.���^�[���E�R�[�h
         ,ov_errmsg               =>  lv_errmsg             -- 12.���[�U�[�E�G���[���b�Z�[�W
        );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --============================
    --3�i�ڃX�e�[�^�X�`�F�b�N
    --============================
    --�i�ڃX�e�[�^�X��'Inactive'����
    --�ڋq�󒍉\�t���O�A����\�t���O�A�݌ɕۗL�\�t���O�A�ԕi�\�t���O
    --�����ꂩ������('N')�ɐݒ肳��Ă����ꍇ
    IF ((lt_item_status           = cv_inactive)
      OR  (lt_cust_order_flg     = cv_n)
      OR  (lt_transaction_enable = cv_n)
      OR  (lt_stock_enabled_flg  = cv_n)
      OR  (lt_return_enable      = cv_n))
    THEN
      --�i�ڃX�e�[�^�X�L���`�F�b�N�G���[
      RAISE chk_item_expt;
    END IF;
--
    --=============================
    --4.�i�ڔ���Ώۋ敪�`�F�b�N
    --=============================
    --NULL�̏ꍇ���G���[�Ƃ���B
    IF (NVL(lt_sales_class, cv_2) <> cv_1) THEN
      --�i�ڔ���Ώۋ敪�L���`�F�b�N�G���[
      RAISE chk_sales_item_expt;
    END IF;
--
    --OUT�p�����[�^�ɐݒ�
    ov_primary_unit := lt_primary_unit;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** �i�ڃX�e�[�^�X�L���`�F�b�N�G���[ ***
    WHEN chk_item_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10291
                 ,iv_token_name1  => cv_tkn_item_code
                 ,iv_token_value1 => lt_item_code
                );
      ov_errmsg  := lv_errmsg;
      lv_errbuf  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                     --# �C�� #
--
    --*** �i�ڔ���Ώۋ敪�L���`�F�b�N�G���[ ***
    WHEN chk_sales_item_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10229
                 ,iv_token_name1  => cv_tkn_item_code
                 ,iv_token_value1 => lt_item_code
                );
      ov_errmsg  := lv_errmsg;
      lv_errbuf  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                     --# �C�� #
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
  END chk_mst_data;
--
  /**********************************************************************************
   * Procedure Name   : get_disposition_id
   * Description      : ����Ȗڕʖ�ID�擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_disposition_id(
    it_base_code          IN  xxcoi_inv_reception_monthly.base_code%TYPE,       -- 1.���_�R�[�h
    in_organization_id    IN  NUMBER,                                           -- 2.�݌ɑg�DID
    on_disposition_id     OUT NUMBER,                                           -- 3.����Ȗڕʖ�ID
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W             --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h               --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_disposition_id'; -- �v���O������
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
    cv_31                 CONSTANT VARCHAR2(2)  := '31';
    --���b�Z�[�W
    cv_xxcoi1_msg_00013   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00013';  --����Ȗڕʖ�ID�擾�G���[
--
    -- *** ���[�J���ϐ� ***
    ln_disposition_id     NUMBER;
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
    --==================================
    --1.����Ȗڕʖ�ID�����ʊ֐����擾
    --==================================
    ln_disposition_id := xxcoi_common_pkg.get_disposition_id(
                              iv_inv_account_kbn  =>  cv_31
                             ,iv_dept_code        =>  it_base_code
                             ,in_organization_id  =>  in_organization_id
                            );
    IF (ln_disposition_id IS NULL) THEN
      RAISE dispo_id_expt;
    END IF;
    --OUT�p�����[�^�ɐݒ�
    on_disposition_id := ln_disposition_id;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** ����Ȗڕʖ�ID�擾�G���[ ***
    WHEN dispo_id_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_00013
                );
      ov_errmsg  := lv_errmsg;
      lv_errbuf  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                     --# �C�� #
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
  END get_disposition_id;
--
  /**********************************************************************************
   * Procedure Name   : ins_tran_interface
   * Description      : ���ގ��OIF�o��(A-5)
   ***********************************************************************************/
  PROCEDURE ins_tran_interface(
    it_inv_seq            IN  xxcoi_inv_reception_monthly.inv_seq%TYPE,             -- 1.�I��SEQ
    it_inventory_item_id  IN  xxcoi_inv_reception_monthly.inventory_item_id%TYPE,   -- 2.�C���^�[�t�F�[�XID
    in_organization_id    IN  NUMBER,                                               -- 3.�捞��
    in_inv_wear           IN  NUMBER,                                               -- 4.���_�R�[�h
    it_primary_unit       IN  mtl_system_items_b.primary_unit_of_measure%TYPE,      -- 5.�I���敪
    iv_period_date        IN  VARCHAR2,                                             -- 6.�I����
    it_subinventory_code  IN  xxcoi_inv_reception_monthly.subinventory_code%TYPE,   -- 7.�q�ɋ敪
    it_tran_id_eki        IN  mtl_transaction_types.transaction_type_id%TYPE,       -- 8.�I���ꏊ
    it_tran_id_son        IN  mtl_transaction_types.transaction_type_id%TYPE,       -- 9.�i�ڃR�[�h
    in_disposition_id     IN  NUMBER,                                               --10.�P�[�X��
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                 --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h                   --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W       --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_tran_interface'; -- �v���O������
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
    cv_1            CONSTANT VARCHAR2(1)  := '1';
    cv_3            CONSTANT VARCHAR2(1)  := '3';
    cv_source_code  CONSTANT VARCHAR2(12) := 'XXCOI006A13C';
    cv_ym           CONSTANT VARCHAR2(6)  := 'YYYYMM';
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --���ގ��OIF�֓o�^
    INSERT INTO mtl_transactions_interface(
       process_flag             -- 1.�v���Z�X�t���O
      ,transaction_mode         -- 2.������[�h
      ,source_code              -- 3.�\�[�X�R�[�h
      ,source_header_id         -- 4.�\�[�X�w�b�_ID
      ,source_line_id           -- 5.�\�[�X���C��ID
      ,inventory_item_id        -- 6.�i��ID
      ,organization_id          -- 7.�݌ɑg�DID
      ,transaction_quantity     -- 8.�������
      ,primary_quantity         -- 9.��P�ʐ���
      ,transaction_uom          --10.����P��
      ,transaction_date         --11.�����
      ,subinventory_code        --12.�ۊǏꏊ
      ,transaction_type_id      --13.����^�C�vID
      ,transaction_source_id    --14.����\�[�XID
      ,last_update_date         --15.�ŏI�X�V��
      ,last_updated_by          --16.�ŏI�X�V��
      ,creation_date            --17.�쐬��
      ,created_by               --18.�쐬��
      ,last_update_login        --19.�ŏI�X�V���[�U
      ,request_id               --20.�v��ID
      ,program_application_id   --21.�v���O�����E�A�v���P�[�V����ID
      ,program_id               --22.�v���O����ID
      ,program_update_date      --23.�v���O�����X�V��
    )VALUES(
       cv_1                                     -- 1.�v���Z�X�t���O
      ,cv_3                                     -- 2.������[�h
      ,cv_source_code                           -- 3.�\�[�X�R�[�h
      ,it_inv_seq                               -- 4.�\�[�X�w�b�_ID
      ,1                                        -- 5.�\�[�X���C��ID
      ,it_inventory_item_id                     -- 6.�i��ID
      ,in_organization_id                       -- 7.�݌ɑg�DID
      ,in_inv_wear                              -- 8.�������
      ,in_inv_wear                              -- 9.��P�ʐ���
      ,it_primary_unit                          --10.����P��
      ,LAST_DAY(TO_DATE(iv_period_date, cv_ym)) --11.�����
      ,it_subinventory_code                     --12.�ۊǏꏊ
      ,DECODE(SIGN(in_inv_wear), -1, it_tran_id_son, it_tran_id_eki)
                                                --13.����^�C�vID
      ,in_disposition_id                        --14.����\�[�XID
      ,SYSDATE                                  --15.�ŏI�X�V��
      ,cn_last_updated_by                       --16.�ŏI�X�V��
      ,SYSDATE                                  --17.�쐬��
      ,cn_created_by                            --18.�쐬��
      ,cn_last_update_login                     --19.�ŏI�X�V���[�U
      ,cn_request_id                            --20.�v��ID
      ,cn_program_application_id                --21.�v���O�����E�A�v���P�[�V����ID
      ,cn_program_id                            --22.�v���O����ID
      ,SYSDATE                                  --23.�v���O�����X�V��
     );
--
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
  END ins_tran_interface;
--
  /**********************************************************************************
   * Procedure Name   : upd_inv_control
   * Description      : �I���Ǘ��X�V(A-6)
   ***********************************************************************************/
  PROCEDURE upd_inv_control(
    iv_period_date        IN  VARCHAR,      --   1.�݌ɉ�v����(�N��)
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_inv_control'; -- �v���O������
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
    cv_2      CONSTANT VARCHAR2(1)  := '2';
    cv_9      CONSTANT VARCHAR2(1)  := '9';
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�I���Ǘ��e�[�u���X�V
    UPDATE  xxcoi_inv_control xic
    SET     xic.inventory_status        = cv_9
           ,xic.last_update_date        = SYSDATE
           ,xic.last_updated_by         = cn_last_updated_by
           ,xic.last_update_login       = cn_last_update_login
           ,xic.request_id              = cn_request_id
           ,xic.program_application_id  = cn_program_application_id
           ,xic.program_id              = cn_program_id
           ,xic.program_update_date     = SYSDATE
    WHERE   xic.inventory_year_month    = iv_period_date    --�N�� = ��v���Ԃ̔N��
    AND     xic.inventory_kbn           = cv_2              --�I���敪 = 2(����)
    ;
--
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
  END upd_inv_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf         OUT VARCHAR2,   --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,   --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --���b�Z�[�W
    cv_xxcoi1_msg_10144   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10144';        --�I���Ǘ����b�N�G���[
    --
    cv_2                  CONSTANT  VARCHAR2(1)   := '2';
    cv_9                  CONSTANT  VARCHAR2(1)   := '9';
--
    -- *** ���[�J���ϐ� ***
--
    lt_old_base_code      xxcoi_inv_reception_monthly.base_code%TYPE;           --OLD���_�R�[�h
    --
    ln_organization_id    NUMBER;                                               --�݌ɑg�DID
    lv_period_date        VARCHAR2(6);                                          --�݌ɉ�v����
    lt_tran_id_son        mtl_transaction_types.transaction_type_id%TYPE;       --����^�C�vID�i�I�����Ց��j
    lt_tran_id_eki        mtl_transaction_types.transaction_type_id%TYPE;       --����^�C�vID�i�I�����Չv�j
    --
    lt_primary_unit       mtl_system_items_b.primary_unit_of_measure%TYPE;      --��P��
    ln_disposition_id     NUMBER;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    --�I�����Տ�񒊏o
    CURSOR get_month_data_cur(
                  in_organization_id  IN NUMBER
                 ,iv_period_date      IN VARCHAR2)
    IS
      SELECT    xirm.inv_seq                                  --�I��SEQ
               ,xirm.base_code                                --���_�R�[�h
               ,xirm.organization_id                          --�g�DID
               ,xirm.subinventory_code                        --�ۊǏꏊ�R�[�h
               ,xirm.inventory_item_id                        --�i��ID
               ,(xirm.inv_wear * -1)  inv_wear                --�I������
      FROM      xxcoi_inv_reception_monthly xirm              --�����݌Ɏ󕥕\
               ,xxcoi_inv_control           xic               --�I���Ǘ�
               ,mtl_secondary_inventories   msi               --�ۊǏꏊ�}�X�^
      WHERE     xirm.organization_id    = in_organization_id
      AND       xirm.inventory_kbn      = cv_2                --�I���敪 = '2'(����)
      AND       xirm.practice_month     = iv_period_date      --�N�� = ��v���ԔN��
      AND       xirm.inv_wear          <> 0                   --�I������ <> 0
      AND       xirm.inv_seq            = xic.inventory_seq
      AND       xirm.subinventory_code  = msi.secondary_inventory_name
-- == 2009/06/03 V1.2 Added START ===============================================================
      AND       xirm.organization_id    = msi.organization_id
-- == 2009/06/03 V1.2 Added END   ===============================================================
-- == 2009/06/26 V1.3 Deleted START ===============================================================
--      AND       msi.attribute5         <> cv_9                --�I���Ώ� <> '9'(�ΏۊO)
-- == 2009/06/26 V1.3 Deleted END   ===============================================================
      ORDER BY  xirm.base_code
               ,xirm.subinventory_code
      FOR UPDATE OF xic.inventory_seq NOWAIT
      ;
    -- <�J�[�\����>���R�[�h�^
    get_month_data_rec get_month_data_cur%ROWTYPE;
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
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- <�������� A-1>
    -- ===============================
    init(
      on_organization_id  =>  ln_organization_id  -- 1.�݌ɑg�D�R�[�h
     ,ov_period_date      =>  lv_period_date      -- 2.�݌ɉ�v����
     ,ot_tran_id_son      =>  lt_tran_id_son      -- 3.���ID�i�I�����Ց��j
     ,ot_tran_id_eki      =>  lt_tran_id_eki      -- 4.���ID�i�I�����Չv�j
     ,ov_errbuf           =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode          =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg           =>  lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <�I�����Տ�񒊏o A-2>
    -- ===============================
    --�I�����Ճf�[�^�擾�J�[�\���I�[�v��
    OPEN get_month_data_cur(
          in_organization_id  => ln_organization_id
         ,iv_period_date      => lv_period_date);
    <<month_data_loop>>
    LOOP
      FETCH get_month_data_cur INTO get_month_data_rec;
      --���f�[�^���Ȃ��Ȃ�����I��
      EXIT WHEN get_month_data_cur%NOTFOUND;
      --�Ώی������Z
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ===============================
      -- <�}�X�^�`�F�b�N A-3>
      -- ===============================
      chk_mst_data(
         it_inventory_item_id => get_month_data_rec.inventory_item_id -- 1.�i��ID
        ,in_organization_id   => ln_organization_id                   -- 2.�݌ɑg�DID
        ,ov_primary_unit      => lt_primary_unit                      -- 3.��P��
        ,ov_errbuf            => lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode           => lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg            => lv_errmsg);                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode <> cv_status_normal) THEN
      --����I���ȊO
        RAISE global_process_expt;
      END IF;
--
      --1���ڂ̃��R�[�h���́A�O���R�[�h�Ƌ��_�R�[�h���Ⴄ�ꍇ
      IF    ((lt_old_base_code IS NULL)
        OR  (get_month_data_rec.base_code <> lt_old_base_code))
      THEN
        -- ===============================
        -- <����Ȗڕʖ�ID�擾 A-4>
        -- ===============================
        get_disposition_id(
           it_base_code         => get_month_data_rec.base_code   -- 1.���_�R�[�h
          ,in_organization_id   => ln_organization_id             -- 2.�݌ɑg�DID
          ,on_disposition_id    => ln_disposition_id              -- 3.����Ȗڕʖ�ID
          ,ov_errbuf            => lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode           => lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg            => lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode <> cv_status_normal) THEN
        --�G���[�I����
          RAISE global_process_expt;
        END IF;
        --�ϐ��ɒl���i�[
        lt_old_base_code    := get_month_data_rec.base_code;
      END IF;
--
      -- ===============================
      -- <���ގ��OIF�o�� A-5>
      -- ===============================
      ins_tran_interface(
         it_inv_seq           => get_month_data_rec.inv_seq           -- 1.�I��SEQ
        ,it_inventory_item_id => get_month_data_rec.inventory_item_id -- 2.�i��ID
        ,in_organization_id   => ln_organization_id                   -- 3.�݌ɑg�DID
        ,in_inv_wear          => get_month_data_rec.inv_wear          -- 4.�I������
        ,it_primary_unit      => lt_primary_unit                      -- 5.��P��
        ,iv_period_date       => lv_period_date                       -- 6.�݌ɉ�v����
        ,it_subinventory_code => get_month_data_rec.subinventory_code -- 7.�ۊǏꏊ
        ,it_tran_id_eki       => lt_tran_id_eki                       -- 8.�I�����Չv
        ,it_tran_id_son       => lt_tran_id_son                       -- 9.�I�����Ց�
        ,in_disposition_id    => ln_disposition_id                    --10.����Ȗڕʖ�ID
        ,ov_errbuf            => lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode           => lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg            => lv_errmsg);                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      --�x���I���̏ꍇ
      IF (lv_retcode <> cv_status_normal) THEN
      --�G���[�I����
        RAISE global_process_expt;
      END IF;
      --���팏���J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP month_data_loop;
    CLOSE get_month_data_cur;
--
    --�Ώی���0���Ȃ�I���Ǘ����X�V���Ȃ�
    IF (gn_target_cnt <> 0) THEN
      -- ===============================
      -- <�I���Ǘ��X�V A-6>
      -- ===============================
      upd_inv_control(
         iv_period_date       => lv_period_date   -- 1.�݌ɉ�v����
        ,ov_errbuf            => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode           => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg            => lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
      --===========================
      --�I������ A-7��main�ɂċL�q
      --===========================
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
    --*** �I���Ǘ����b�N�擾�G���[ ***
    WHEN lock_expt THEN
      IF (get_month_data_cur%ISOPEN) THEN
        CLOSE get_month_data_cur;
      END IF;
      --�G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      --���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10144
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (get_month_data_cur%ISOPEN) THEN
        CLOSE get_month_data_cur;
      END IF;
      --�G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (get_month_data_cur%ISOPEN) THEN
        CLOSE get_month_data_cur;
      END IF;
      --�G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (get_month_data_cur%ISOPEN) THEN
        CLOSE get_month_data_cur;
      END IF;
      --�G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
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
    errbuf            OUT   VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT   VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
       ov_errbuf          =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode         =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg          =>  lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      IF (lv_errmsg IS NOT NULL) THEN
        --��s�}��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
      END IF;
-- == 2009/05/08 V1.1 Added START ==================================================================
      -- �������������Z�b�g
      gn_normal_cnt := 0;
-- == 2009/05/08 V1.1 Added END   ==================================================================
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
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
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
END XXCOI006A13C;
/
