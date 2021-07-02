CREATE OR REPLACE PACKAGE BODY      XXCOK024A39C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024AxxC(body)
 * Description      : �������l�������̍T���f�[�^�쐬
 * MD.050           : �������l�������̍T���f�[�^�쐬 MD050_COK_024_A39
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  proc_init            ��������(A-1)
 *
 *  upd_control_p        �̔��T���Ǘ����X�V(A-4)
 *  submain              ���C�������v���V�[�W��
 *                          �Eproc_init
 *                       �������l���������̎擾(A-2)
 *                       �T���f�[�^�o�^(A-3)
 *                       ���C�������v���V�[�W��
 *                       �ŃR�[�h�`�F�b�N(A-4)
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                          �Esubmain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2021/06/22    1.0   K.Yoshikawa      main�V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal               CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn                 CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error                CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  --WHO�J����
  cn_created_by                  CONSTANT NUMBER      := fnd_global.user_id;            -- CREATED_BY
  cd_creation_date               CONSTANT DATE        := SYSDATE;                       -- CREATION_DATE
  cn_last_updated_by             CONSTANT NUMBER      := fnd_global.user_id;            -- LAST_UPDATED_BY
  cd_last_update_date            CONSTANT DATE        := SYSDATE;                       -- LAST_UPDATE_DATE
  cn_last_update_login           CONSTANT NUMBER      := fnd_global.login_id;           -- LAST_UPDATE_LOGIN
  cn_request_id                  CONSTANT NUMBER      := fnd_global.conc_request_id;    -- REQUEST_ID
  cn_program_application_id      CONSTANT NUMBER      := fnd_global.prog_appl_id;       -- PROGRAM_APPLICATION_ID
  cn_program_id                  CONSTANT NUMBER      := fnd_global.conc_program_id;    -- PROGRAM_ID
  cd_program_update_date         CONSTANT DATE        := SYSDATE;                       -- PROGRAM_UPDATE_DATE
  cv_msg_part                    CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                    CONSTANT VARCHAR2(3) := '.';
  cv_control_flag_u              CONSTANT VARCHAR2(1) := 'U';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                     VARCHAR2(2000);
  gv_sep_msg                     VARCHAR2(2000);
  gv_exec_user                   VARCHAR2(100);
  gv_conc_name                   VARCHAR2(30);
  gv_conc_status                 VARCHAR2(30);
  gn_target_cnt                  NUMBER;                    -- �Ώی���
  gn_normal_cnt                  NUMBER;                    -- ���팏��
  gn_rate_skip_cnt               NUMBER;                    -- �U�֊���100%�ȊO�ŃX�L�b�v��������
  gn_error_cnt                   NUMBER;                    -- �G���[����
  gn_warn_cnt                    NUMBER;                    -- �X�L�b�v����
  gn_warn_tax_cnt                NUMBER;                    -- �ŃR�[�h�x���X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt            EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt                EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt         EXCEPTION;
  global_check_lock_expt         EXCEPTION;                 -- ���b�N�擾�G���[
  --
  --*** ���O�̂ݏo�͗�O ***
  global_api_expt_log            EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_check_lock_expt, -54);
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(30)  := 'XXCOK024A39C';       -- �p�b�P�[�W��
--
  cv_appl_name_xxcok             CONSTANT VARCHAR2(5)   := 'XXCOK';              -- �A�v���P�[�V�����Z�k��
  -- ���b�Z�[�W
  cv_msg_xxcok_00001             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00001';   -- �Ώۃf�[�^�Ȃ�
  cv_msg_xxcok_00003             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00003';   -- �v���t�@�C���擾�G���[
--
--
  cv_msg_xxcok_10592             CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10592';   -- �O�񏈗�ID�擾�G���[
  cv_msg_xxcok_10798             CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10798';   -- �������l���̃f�[�^��ގ擾�G���[
  cv_msg_xxcok_10799             CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10799';   -- �ŃR�[�h�`�F�b�N�G���[
  cv_msg_xxcok_10800             CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10800';   -- �ŃR�[�h�擾�G���[

  cv_msg_proc_date_err           CONSTANT  VARCHAR2(100):= 'APP-XXCOK1-00028';   -- �Ɩ����t�擾�G���[���b�Z�[�W
  -- �g�[�N��
  cv_tkn_profile                 CONSTANT VARCHAR2(10)  := 'PROFILE';            -- �g�[�N���F�v���t�@�C����
  cv_tkn_sqlerrm                 CONSTANT VARCHAR2(10)  := 'SQLERRM';            -- �g�[�N���FSQL�G���[
  cv_tkn_file_name               CONSTANT VARCHAR2(10)  := 'FILE_NAME';          -- �g�[�N���FSQL�G���[
--
  cv_date_fmt_ymd                CONSTANT VARCHAR2(10)  := 'RRRRMMDD';           -- YYYYMMDD
  cv_date_fmt_dt_ymdhms          CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_date_fmt_dt_ymdhms;
                                                                                 -- YYYYMMDDHH24MISS
--
  cv_item_code_dummy_NT          CONSTANT VARCHAR2(33)  := 'XXCOK1_ITEM_CODE_DUMMY_NT';  -- XXCOK:�i�ڃR�[�h_�_�~�[�l�i�������l�������j
--
  cv_company_code                CONSTANT VARCHAR2(3)   := '001';                -- ��ЃR�[�h
  cv_status_new                  CONSTANT VARCHAR2(1)   := 'N';                  -- �X�e�[�^�X N �V�K
  cv_source_category_u           CONSTANT VARCHAR2(1)   := 'U';                  -- �쐬���敪 U �A�b�v���[�h
  cv_data_type_lookup            CONSTANT VARCHAR2(30)  := 'XXCOK1_DEDUCTION_DATA_TYPE'; -- �f�[�^��� �Q�ƃ^�C�v
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_proc_date                   DATE;                                          -- �Ɩ����t
  gv_item_code_dummy_NT          VARCHAR2(7);                                   -- �_�~�[�i�ڃR�[�h�i�������l�������j
  gn_target_trx_line_id_st_1     NUMBER;                                        -- AR�������ID (��)
  gn_target_trx_line_id_ed_1     NUMBER;                                        -- AR�������ID (��)
  gv_data_type                   VARCHAR2(30);                                  -- �������l���f�[�^���
  gv_segment3                    VARCHAR2(25);                                  -- �������l�����Ȗ�
  gv_segment4                    VARCHAR2(25);                                  -- �������l�����Ȗڕ⏕
  gd_record_date                 DATE;                                          -- �v���
  gn_org_id                      NUMBER;                                        -- �c�ƒP��
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : ���������v���V�[�W��(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf      OUT    VARCHAR2         --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT    VARCHAR2         --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT    VARCHAR2         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'proc_init';          -- �v���O������
--
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(100);                                  -- �X�e�b�v
    lv_message_token          VARCHAR2(100);                                  -- �A�g���t
    --
    -- *** ���[�U�[��`��O ***
    profile_expt              EXCEPTION;                                      -- �v���t�@�C���擾��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Ɩ����t�̎擾
    lv_step := 'A-1.1';
    lv_message_token := '�Ɩ����t�̎擾';
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_appl_name_xxcok,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt_log;
    END IF;
--
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => '�Ɩ����t:'||gd_proc_date
                      );
--
    -- �O���������擾
    gd_record_date := last_day(add_months(trunc(gd_proc_date,'month'),-1));
--
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => '�O������:'||gd_record_date
                      );
--
    -- �v���t�@�C���擾
    lv_step := 'A-1.2';
    lv_message_token := '�_�~�[�i�ڃR�[�h�i�������l�������j�̎擾';
--
    -- �_�~�[�i�ڃR�[�h�̎擾
    gv_item_code_dummy_NT := FND_PROFILE.VALUE( cv_item_code_dummy_NT );
    -- �擾�G���[��
    IF ( gv_item_code_dummy_NT IS NULL ) THEN
      lv_message_token := cv_item_code_dummy_NT;
      RAISE profile_expt;
    END IF;
--
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => '�_�~�[�i�ڃR�[�h:'||gv_item_code_dummy_NT
                      );
--
    -- �������l���̃f�[�^��ށA�ȖځA�⏕�擾
    lv_step := 'A-1.4';
    lv_message_token := '�������l���̃f�[�^��ށA�ȖځA�⏕�擾';
-- 
    BEGIN
--
      SELECT fvl.lookup_code
            ,fvl.attribute6
            ,fvl.attribute7
      INTO   gv_data_type
            ,gv_segment3
            ,gv_segment4
      FROM apps.fnd_lookup_values_vl fvl
      WHERE fvl.lookup_type = cv_data_type_lookup
      AND fvl.lookup_code = ( SELECT min(fvl.lookup_code)
                              FROM apps.fnd_lookup_values_vl fvl
                              WHERE fvl.lookup_type = cv_data_type_lookup
                              AND fvl.ENABLED_FLAG      =  'Y'
                              AND nvl(fvl.START_DATE_ACTIVE,to_date('19900101','RRRRMMDD')) <= gd_record_date
                              AND nvl(fvl.END_DATE_ACTIVE,to_date('29900101','RRRRMMDD'))   >= gd_record_date
                              AND attribute10       =  'Y' );
--
    EXCEPTION
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_appl_name_xxcok
                      , cv_msg_xxcok_10798
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    
    IF (gv_data_type is null or
        gv_segment3  is null or
        gv_segment4  is null) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_appl_name_xxcok
                      , cv_msg_xxcok_10798
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END IF;
--
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => '�������l���̃f�[�^��ށA�ȖځA�⏕:'||gv_data_type||','||gv_segment3||','||gv_segment4
                      );
--
    -- �c�ƒP��
    lv_step := 'A-1.5';
    gn_org_id := FND_PROFILE.VALUE( 'ORG_ID' );
    IF gn_org_id IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appl_name_xxcok
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,'ORG_ID'
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => '�c�ƒP��:'||gn_org_id
                      );
--
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    -- �J�[�\���̃N���[�Y�������ɋL�q����
    --*** �v���t�@�C���擾�G���[ ***
    WHEN profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok            -- �A�v���P�[�V�����Z�k���FXXCOK
                     ,iv_name         => cv_msg_xxcok_00003            -- ���b�Z�[�W�FAPP-XXCOK1-00003 �v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tkn_profile                -- �g�[�N���FPROFILE
                     ,iv_token_value1 => lv_message_token              -- �v���t�@�C����
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf      OUT    VARCHAR2         --   �G���[�E���b�Z�[�W            --# �Œ� #
   ,ov_retcode     OUT    VARCHAR2         --   ���^�[���E�R�[�h              --# �Œ� #
   ,ov_errmsg      OUT    VARCHAR2         --   ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'submain';            -- �v���O������
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step                   VARCHAR2(100);                                  -- �X�e�b�v
    lb_retcode                BOOLEAN             DEFAULT NULL;               -- ���b�Z�[�W�o�͊֐��̖߂�l
     --###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[���[�J���ϐ�
    -- ===============================
    lv_sqlerrm                VARCHAR2(5000);                                 -- SQLERRM�ޔ�
    lv_message_token          VARCHAR2(100);                                  -- �A�g���t
    lv_item_code              VARCHAR2(7);                                    -- �i�ڃR�[�h
    lv_trx_number             VARCHAR2(20);                                   -- AR����ԍ�
    ln_trx_line_cnt           NUMBER :=  0;                                   -- AR������ו�����
    ln_rec_amount_div_rem     NUMBER :=  0;                                   -- ������z�c
    ln_tax_amount_div_rem     NUMBER :=  0;                                   -- �ŋ����z�c
    ln_line_number            NUMBER :=  0;                                   -- AR������הԍ�
    ln_rec_amount_div         NUMBER :=  0;                                   -- ������z
    ln_tax_amount_div         NUMBER :=  0;                                   -- �ŋ����z
    lv_conv_tax_code          VARCHAR2(50);                                   -- �ϊ���ŃR�[�h
    lv_conv_tax_rate          NUMBER  :=  0;                                  -- �ϊ���ŗ�
    lv_skip_flag              VARCHAR2(1);                                    -- �X�L�b�v�t���O
    ln_from_customer          VARCHAR2(9);                                    -- �U�֌��ڋq
    ln_to_customer            VARCHAR2(9);                                    -- �U�֐�ڋq
    ln_from_base              VARCHAR2(4);                                    -- �U�֌����_
    ln_to_base                VARCHAR2(4);                                    -- �U�֐拒�_
    lv_out_msg                VARCHAR2(1000)      DEFAULT NULL;               -- ���b�Z�[�W�o�͕ϐ�
--
    -- �������l���������J�[�\��
    --lv_step := 'A-2.1';
    CURSOR customer_trx_line_cur
    IS
    SELECT     trxl.trx_number                           trx_number,                                                    -- �[�i�`�[no�iar����ԍ��j
               trxl.trx_date                             trx_date,                                                      -- �[�i���i������j�i������j
               trxl.customer_trx_id                      customer_trx_id,                                               -- ���ID
               trxl.ship_to_customer_id                  ship_to_customer_id,                                           -- �[�i��ڋqID
               trxl.ship_to_customer_code                ship_to_customer_code,                                         -- �[�i��ڋq�R�[�h 
               trxl.customer_trx_line_id                 customer_trx_line_id,                                          -- ����ID            
               trxl.line_number                          line_number,                                                   -- ���הԍ�
               trxl.item_code                            item_code,                                                     -- ���i�R�[�h
               trxl.rec_amount                           rec_amount,                                                    -- ������z
               trxl.tax_amount                           tax_amount,                                                    -- �ŋ����z
               trxl.comp_code                            comp_code,                                                     -- ��ЃR�[�h(aff1)
               trxl.dept_code                            dept_code,                                                     -- ���㋒�_�R�[�h(aff2)
               trxl.kamoku                               kamoku,                                                        -- �Ȗ�
               trxl.hojyo                                hojyo,                                                         -- �⏕�Ȗ�
               trxl.gl_date                              gl_date,                                                       -- GL�L����
               trxl.trx_type_name                        trx_type_name,                                                 -- ����^�C�v��
               trxl.vat_tax_id                           vat_tax_id,                                                    -- �ŃR�[�h
               trxl.ship_to_past_sale_base_code          ship_to_past_sale_base_code,                                   -- �[�i��ڋq�O�����㋒�_
               xsri2.selling_trns_rate_info_id           selling_trns_rate_info_id,                                     -- �U�֊���ID
               xsri2.selling_from_base_code              selling_from_base_cod,                                         -- �U�֌����_
               xsri2.selling_from_cust_code              selling_from_cust_code,                                        -- �U�֌��ڋq
               xsri2.from_cust_past_sale_base_code       from_cust_past_sale_base_code,                                 -- �U�֌��ڋq�O�����㋒�_
               xsri2.selling_to_cust_code                selling_to_cust_code,                                          -- �U�֐�ڋq
               xsri2.to_cust_past_sale_base_code         to_cust_past_sale_base_code,                                   -- �U�֐�ڋq�O�����㋒�_
               xsri2.selling_trns_rate                   selling_trns_rate,                                             -- �U�֊���
               xsri2.invalid_flag                        invalid_flag,                                                  -- �L���t���O
               round(trxl.rec_amount * nvl(xsri2.selling_trns_rate,100) /100)
                                                         rec_amount_div,                                                -- ������z��
               round(trxl.tax_amount * nvl(xsri2.selling_trns_rate,100) /100)
                                                         tax_amount_div,                                                -- �ŋ����z��
               count(1) over(partition by  trxl.customer_trx_line_id)
                                                         cnt_trx_line,                                                  -- ���׈�����
               sum(xsri2.selling_trns_rate) over(partition by  trxl.customer_trx_line_id)
                                                         sum_trns_rate                                                  -- �U�֊������v
    FROM
              (SELECT rcta.trx_number               trx_number,                                                         -- �[�i�`�[no�iar����ԍ��j
                      rcta.trx_date                 trx_date,                                                           -- �[�i���i������j�i������j
                      rcta.customer_trx_id          customer_trx_id,                                                    -- ���id
                      rcta.ship_to_customer_id      ship_to_customer_id,                                                -- �[�i��ڋqid
                      hca.account_number            ship_to_customer_code,                                              -- �[�i��ڋq�R�[�h 
                      rctla.customer_trx_line_id    customer_trx_line_id,                                               -- ����id            
                      rctla.line_number             line_number,                                                        -- ���הԍ�
                      rctta.attribute3              item_code,                                                          -- ���i�R�[�h
                      rctla.revenue_amount          rec_amount,                                                         -- ������z
                      rctla_t.extended_amount       tax_amount,                                                         -- �ŋ����z
                      gcc.segment1                  comp_code,                                                          -- ��ЃR�[�h(aff1)
                      gcc.segment2                  dept_code,                                                          -- ���㋒�_�R�[�h(aff2)
                      gcc.segment3                  kamoku,                                                             -- �Ȗ�
                      gcc.segment4                  hojyo,                                                              -- �⏕�Ȗ�
                      rctlgda.gl_date               gl_date,                                                            -- gl�L����
                      rctta.name                    trx_type_name,                                                      -- ����^�C�v��
                      rctla.vat_tax_id              vat_tax_id,                                                         -- �ŃR�[�h
                      xca.past_sale_base_code       ship_to_past_sale_base_code                                         -- �[�i��ڋq�O�����㋒�_
              FROM    apps.ra_customer_trx_all              rcta,                                                       -- ����w�b�_
                      apps.ra_cust_trx_types_all            rctta,                                                      -- ����^�C�v
                      apps.ra_customer_trx_lines_all        rctla,                                                      -- ������ׁi�{�́j
                      apps.ra_customer_trx_lines_all        rctla_t,                                                    -- ������ׁi�Ŋz�j
                      apps.ra_cust_trx_line_gl_dist_all     rctlgda,                                                    -- ����z��
                      apps.gl_code_combinations             gcc,                                                        -- ����Ȗڑg�����}�X�^
                      apps.hz_cust_accounts                 hca,                                                        -- �ڋq�}�X�^
                      apps.xxcmm_cust_accounts              xca                                                         -- �ڋq�ǉ����
              WHERE   rcta.cust_trx_type_id           =  rctta.cust_trx_type_id
              AND     rctla.line_type                 =  'LINE'
              AND     rctlgda.gl_date                 >= trunc (gd_record_date,'month')                                 -- �O��1��
              AND     rctlgda.gl_date                 <= gd_record_date                                                 -- �O������
              AND     rcta.customer_trx_id            =  rctla.customer_trx_id
              AND     rctla.customer_trx_line_id      =  rctla_t.link_to_cust_trx_line_id(+)
              AND     rctla.customer_trx_line_id      =  rctlgda.customer_trx_line_id
              AND     rctlgda.code_combination_id     =  gcc.code_combination_id 
              AND     hca.cust_account_id             =  rcta.ship_to_customer_id
              AND     xca.customer_code               =  hca.account_number
              AND     gcc.segment3                    =  gv_segment3 --'41507'
              AND     gcc.segment4                    =  gv_segment4 --'02252'
              AND     rctta.name                      in (SELECT fvl.meaning
                                                          FROM   apps.fnd_lookup_values_vl fvl
                                                          WHERE  fvl.lookup_type = 'XXCOK1_TRX_TYPE_DISC'
                                                          AND    fvl.ENABLED_FLAG      =  'Y'
                                                          AND    nvl(fvl.START_DATE_ACTIVE,to_date('19900101','RRRRMMDD')) <= gd_record_date
                                                          AND    nvl(fvl.END_DATE_ACTIVE,to_date('29900101','RRRRMMDD'))   >= gd_record_date 
                                                          )                                                               -- �������l������','��� �������l��
              AND     rcta.customer_trx_id            not in (
                                                           SELECT  customer_trx_id
                                                           FROM    apps.ra_customer_trx_lines_all ractal_2
                                                                  ,apps.ar_vat_tax_all     avta_2      
                                                           WHERE   avta_2.vat_tax_id       = ractal_2.vat_tax_id
                                                           AND     avta_2.attribute4       is null
                                                           AND     ractal_2.customer_trx_id = rcta.customer_trx_id
                                                           )                                                            -- '9910','9908'�ȊO�̐ŃR�[�h���܂܂��ꍇ����w�b�_�[�P�ʂŏ��O
              ) trxl,
              (SELECT xsri.selling_trns_rate_info_id    selling_trns_rate_info_id,                                      -- �[�i��ڋq�O�����㋒�_
                      xsri.selling_from_base_code       selling_from_base_code,                                         -- �U�֊���ID
                      xsri.selling_from_cust_code       selling_from_cust_code,                                         -- �U�֌����_
                      xca1.past_sale_base_code          from_cust_past_sale_base_code,                                  -- �U�֌��ڋq
                      xsri.selling_to_cust_code         selling_to_cust_code,                                           -- �U�֌��ڋq�O�����㋒�_
                      xca2.past_sale_base_code          to_cust_past_sale_base_code,                                    -- �U�֐�ڋq
                      xsri.selling_trns_rate            selling_trns_rate,                                              -- �U�֐�ڋq�O�����㋒�_
                      xsri.invalid_flag                 invalid_flag                                                    -- �U�֊���
              FROM apps.xxcok_selling_rate_info         xsri                                                            -- �L���t���O
                  ,apps.xxcmm_cust_accounts             xca1
                  ,apps.xxcmm_cust_accounts             xca2
              where 1=1
              AND  xsri.selling_from_cust_code   = xca1.customer_code(+)
              AND  xsri.selling_to_cust_code     = xca2.customer_code(+)
              AND  xsri.invalid_flag             = '0' --cv_invalid_flag_valid
              AND  xca1.selling_transfer_div     = '1'
              AND  exists ( SELECT /*+ leading( xsfi,xsti ) */
                            'x'
                            FROM apps.xxcok_selling_from_info    xsfi
                               , apps.xxcok_selling_to_info      xsti
                            WHERE xsfi.selling_from_base_code     = xsri.selling_from_base_code
                            AND xsfi.selling_from_cust_code     = xsri.selling_from_cust_code
                            AND xsfi.selling_from_info_id       = xsti.selling_from_info_id
                            AND xsti.selling_to_cust_code       = xsri.selling_to_cust_code
                            AND xsti.start_month               <= to_char(gd_record_date,'RRRRMM')  --������͂��v�サ����
                            AND xsti.invalid_flag               = 0 --cv_invalid_flag_valid
                            AND rownum                          = 1
                        )
              ) xsri2
    WHERE 1=1
    AND   trxl.ship_to_customer_code = xsri2.selling_from_cust_code(+)
    AND   trxl.ship_to_past_sale_base_code = xsri2.selling_from_base_code(+)
    ORDER BY trxl.trx_number
         ,trxl.line_number
         ,selling_trns_rate_info_id;
--
    TYPE customer_trx_line_ttype IS TABLE OF customer_trx_line_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    lt_customer_trx_line_tab       customer_trx_line_ttype;               -- �������l�������f�[�^
--
    -- �ŃR�[�h�`�F�b�N�J�[�\��
    --lv_step := 'A-2.2';
    CURSOR tax_check_cur
    IS
--
              SELECT  rcta.trx_number
                     ,rctla.line_number
              FROM    apps.ra_customer_trx_all              rcta,                                                       -- ����w�b�_
                      apps.ra_cust_trx_types_all            rctta,                                                      -- ����^�C�v
                      apps.ra_customer_trx_lines_all        rctla,                                                      -- ������ׁi�{�́j
                      apps.ra_customer_trx_lines_all        rctla_t,                                                    -- ������ׁi�Ŋz�j
                      apps.ra_cust_trx_line_gl_dist_all     rctlgda,                                                    -- ����z��
                      apps.gl_code_combinations             gcc,                                                        -- ����Ȗڑg�����}�X�^
                      apps.hz_cust_accounts                 hca,                                                        -- �ڋq�}�X�^
                      apps.xxcmm_cust_accounts              xca                                                         -- �ڋq�ǉ����
              WHERE   rcta.cust_trx_type_id           =  rctta.cust_trx_type_id
              AND     rctla.line_type                 =  'LINE'
              AND     rctlgda.gl_date                 >= trunc (gd_record_date,'month')                                 -- �O��1��
              AND     rctlgda.gl_date                 <= gd_record_date                                                 -- �O������
              AND     rcta.customer_trx_id            =  rctla.customer_trx_id
              AND     rctla.customer_trx_line_id      =  rctla_t.link_to_cust_trx_line_id(+)
              AND     rctla.customer_trx_line_id      =  rctlgda.customer_trx_line_id
              AND     rctlgda.code_combination_id     =  gcc.code_combination_id 
              AND     hca.cust_account_id             =  rcta.ship_to_customer_id
              AND     xca.customer_code               =  hca.account_number
              AND     gcc.segment3                    =  gv_segment3 --'41507'
              AND     gcc.segment4                    =  gv_segment4 --'02252'
              AND     rctta.name                      in (SELECT fvl.meaning
                                                          FROM   apps.fnd_lookup_values_vl fvl
                                                          WHERE  fvl.lookup_type = 'XXCOK1_TRX_TYPE_DISC'
                                                          AND    fvl.ENABLED_FLAG      =  'Y'
                                                          AND    nvl(fvl.START_DATE_ACTIVE,to_date('19900101','RRRRMMDD')) <= gd_record_date
                                                          AND    nvl(fvl.END_DATE_ACTIVE,to_date('29900101','RRRRMMDD'))   >= gd_record_date 
                                                          )                                                               -- �������l������','��� �������l��
              AND     rcta.customer_trx_id            in (
                                                           SELECT  customer_trx_id
                                                           FROM    apps.ra_customer_trx_lines_all ractal_2
                                                                  ,apps.ar_vat_tax_all     avta_2      
                                                           WHERE   avta_2.vat_tax_id       = ractal_2.vat_tax_id
                                                           AND     avta_2.attribute4       is null
                                                           AND    ractal_2.customer_trx_id = rcta.customer_trx_id
                                                           )
              ORDER BY rcta.trx_number
                      ,rctla.line_number;
--
    TYPE tax_check_ttype IS TABLE OF tax_check_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    lt_tax_check_tab       tax_check_ttype;    -- �ŃR�[�h�s���f�[�^
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    subproc_expt              EXCEPTION;       -- �T�u�v���O�����G���[
    file_open_expt            EXCEPTION;       -- �t�@�C���I�[�v���G���[
    file_output_expt          EXCEPTION;       -- �t�@�C���������݃G���[
    file_close_expt           EXCEPTION;       -- �t�@�C���N���[�Y�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt     := 0;
    gn_rate_skip_cnt  := 0;
    gn_normal_cnt     := 0;
    gn_error_cnt      := 0;
    gn_warn_cnt       := 0;
    gn_warn_tax_cnt   := 0;
--
    -- ===============================================
    -- proc_init�̌Ăяo���i����������proc_init�ōs���j
    -- ===============================================
    proc_init(
       ov_errbuf      => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode     => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg      => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE subproc_expt;
    END IF;
--
    -----------------------------------
    -- A-2.�������l���������̎擾
    -----------------------------------
    lv_step := 'A-2';
--
    OPEN  customer_trx_line_cur;
    FETCH customer_trx_line_cur BULK COLLECT INTO lt_customer_trx_line_tab;
    CLOSE customer_trx_line_cur;
    -- ���������J�E���g
    gn_target_cnt := lt_customer_trx_line_tab.COUNT;
--
    -----------------------------------------------
    -- A-3.�T���f�[�^�o�^
    -----------------------------------------------
    lv_step := 'A-3';
--
      <<out_trx_line_loop>>
      FOR i IN 1..lt_customer_trx_line_tab.COUNT LOOP
--
         lv_errmsg := '����ԍ��F' || lt_customer_trx_line_tab( i ).trx_number || '���הԍ��F' || lt_customer_trx_line_tab( i ).line_number;
         lv_errbuf :=  lv_errmsg;
--
         lv_skip_flag := 'N';
--
         --���ׂ��u���[�N�����猏���Ǝc�z�����Z�b�g
         IF lv_trx_number || ln_line_number <> lt_customer_trx_line_tab( i ).trx_number || lt_customer_trx_line_tab( i ).line_number THEN
            ln_trx_line_cnt       := 1;
            ln_rec_amount_div_rem := lt_customer_trx_line_tab( i ).rec_amount;
            ln_tax_amount_div_rem := lt_customer_trx_line_tab( i ).tax_amount;
         ELSE
            ln_trx_line_cnt       := ln_trx_line_cnt + 1;
         END IF;
--
         --AR������ז��̍ŏI�������R�[�h�̏ꍇ�́A�[�������̂��ߖ��׋��z����o�͍ς݋��z�̍��z���T�����z�Ƃ���INSERT
         IF ln_trx_line_cnt = lt_customer_trx_line_tab( i ). cnt_trx_line  THEN
            ln_rec_amount_div     := ln_rec_amount_div_rem;
            ln_tax_amount_div     := ln_tax_amount_div_rem;
--
            ln_from_customer      :=lt_customer_trx_line_tab( i ).ship_to_customer_code;
            ln_to_customer        :=nvl(lt_customer_trx_line_tab( i ).selling_to_cust_code, lt_customer_trx_line_tab( i ).ship_to_customer_code);
            ln_from_base          :=nvl(lt_customer_trx_line_tab( i ).to_cust_past_sale_base_code, lt_customer_trx_line_tab( i ).ship_to_past_sale_base_code);
            ln_to_base            :=nvl(lt_customer_trx_line_tab( i ).to_cust_past_sale_base_code, lt_customer_trx_line_tab( i ).ship_to_past_sale_base_code);
--
            --�U�֊�����100%�łȂ��ꍇ�͐U�֌��ōT���f�[�^���쐬
            IF lt_customer_trx_line_tab( i ).sum_trns_rate <> 100 THEN
               ln_rec_amount_div  := lt_customer_trx_line_tab( i ).rec_amount;
               ln_tax_amount_div  := lt_customer_trx_line_tab( i ).tax_amount;
--
               ln_from_customer   :=lt_customer_trx_line_tab( i ).ship_to_customer_code;
               ln_to_customer     :=lt_customer_trx_line_tab( i ).ship_to_customer_code;
               ln_from_base       :=lt_customer_trx_line_tab( i ).ship_to_past_sale_base_code;
               ln_to_base         :=lt_customer_trx_line_tab( i ).ship_to_past_sale_base_code;
--
            END IF;
         ELSE
            ln_rec_amount_div     := lt_customer_trx_line_tab( i ).rec_amount_div;
            ln_tax_amount_div     := lt_customer_trx_line_tab( i ).tax_amount_div;
--
            ln_from_customer      :=lt_customer_trx_line_tab( i ).ship_to_customer_code;
            ln_to_customer        :=nvl(lt_customer_trx_line_tab( i ).selling_to_cust_code, lt_customer_trx_line_tab( i ).ship_to_customer_code);
            ln_from_base          :=nvl(lt_customer_trx_line_tab( i ).to_cust_past_sale_base_code, lt_customer_trx_line_tab( i ).ship_to_past_sale_base_code);
            ln_to_base            :=nvl(lt_customer_trx_line_tab( i ).to_cust_past_sale_base_code, lt_customer_trx_line_tab( i ).ship_to_past_sale_base_code);
--
            --�U�֊�����100%�łȂ��ꍇ�͍ŏI�s�ȊO�̓X�L�b�v
            IF lt_customer_trx_line_tab( i ).sum_trns_rate <> 100 THEN
               lv_skip_flag := 'Y';
               gn_rate_skip_cnt := gn_rate_skip_cnt + 1;
            END IF;
         END IF;
--
         IF lv_skip_flag = 'N' THEN
             --�ŃR�[�h�ϊ�
            lv_step := 'A-3.1a';
            BEGIN
--
              SELECT   avta.attribute4
                      ,avta2.tax_rate
              INTO     lv_conv_tax_code
                      ,lv_conv_tax_rate
              FROM     ar_vat_tax_all avta
                      ,ar_vat_tax_all avta2
              WHERE    avta2.tax_code     =  avta.attribute4
              AND      avta.org_id        =  gn_org_id
              AND      nvl(avta.start_date,to_date('19900101','RRRRMMDD'))    <= gd_record_date
              AND      nvl(avta.end_date,to_date('29990101','RRRRMMDD'))      >= gd_record_date
              AND      avta.enabled_flag  =  'Y'
              AND      avta.vat_tax_id    =  lt_customer_trx_line_tab( i ).vat_tax_id
              AND      avta2.org_id       =  gn_org_id
              AND      nvl(avta2.start_date,to_date('19900101','RRRRMMDD'))   <= gd_record_date
              AND      nvl(avta2.end_date,to_date('29990101','RRRRMMDD'))     >= gd_record_date
              AND      avta2.enabled_flag =  'Y';
              --
            EXCEPTION
              WHEN  OTHERS THEN
                       lv_errmsg :=  xxccp_common_pkg.get_msg(
                                     cv_appl_name_xxcok
                                   , cv_msg_xxcok_10800
                                   );
                       lv_errbuf :=  lv_errmsg;
                       RAISE global_process_expt;
            END;
--
          -- �T���f�[�^INSERT
          lv_step := 'A-3.1b';
            INSERT INTO xxcok_sales_deduction(sales_deduction_id                                           --�̔��T��ID
                                             ,base_code_from                                               --�U�֌����_
                                             ,base_code_to                                                 --�U�֐拒�_
                                             ,customer_code_from                                           --�U�֌��ڋq�R�[�h
                                             ,customer_code_to                                             --�U�֐�ڋq�R�[�h
                                             ,deduction_chain_code                                         --�T���p�`�F�[���R�[�h
                                             ,corp_code                                                    --��ƃR�[�h
                                             ,record_date                                                  --�v���
                                             ,source_category                                              --�쐬���敪
                                             ,source_line_id                                               --�쐬������ID
                                             ,condition_id                                                 --�T������ID
                                             ,condition_no                                                 --�T���ԍ�
                                             ,condition_line_id                                            --�T���ڍ�ID
                                             ,data_type                                                    --�f�[�^���
                                             ,status                                                       --�X�e�[�^�X
                                             ,item_code                                                    --�i�ڃR�[�h
                                             ,sales_uom_code                                               --�̔��P��
                                             ,sales_unit_price                                             --�̔��P��
                                             ,sales_quantity                                               --�̔�����
                                             ,sale_pure_amount                                             --����{�̋��z
                                             ,sale_tax_amount                                              --�������Ŋz
                                             ,deduction_uom_code                                           --�T���P��
                                             ,deduction_unit_price                                         --�T���P��
                                             ,deduction_quantity                                           --�T������
                                             ,deduction_amount                                             --�T���z
                                             ,compensation                                                 --��U
                                             ,margin                                                       --�≮�}�[�W��
                                             ,sales_promotion_expenses                                     --�g��
                                             ,margin_reduction                                             --�≮�}�[�W�����z
                                             ,tax_code                                                     --�ŃR�[�h
                                             ,tax_rate                                                     --�ŗ�
                                             ,recon_tax_code                                               --�������ŃR�[�h
                                             ,recon_tax_rate                                               --�������ŗ�
                                             ,deduction_tax_amount                                         --�T���Ŋz
                                             ,remarks                                                      --���l
                                             ,application_no                                               --�\����No.
                                             ,gl_if_flag                                                   --GL�A�g�t���O
                                             ,gl_base_code                                                 --GL�v�㋒�_
                                             ,gl_date                                                      --GL�L����
                                             ,recovery_date                                                --���J�o���f�[�^�ǉ������t
                                             ,recovery_add_request_id                                      --���J�o���f�[�^�ǉ����v��ID
                                             ,recovery_del_date                                            --���J�o���f�[�^�폜�����t
                                             ,recovery_del_request_id                                      --���J�o���f�[�^�폜���v��ID
                                             ,cancel_flag                                                  --����t���O
                                             ,cancel_base_code                                             --������v�㋒�_
                                             ,cancel_gl_date                                               --���GL�L����
                                             ,cancel_user                                                  --������{���[�U
                                             ,recon_base_code                                              --�������v�㋒�_
                                             ,recon_slip_num                                               --�x���`�[�ԍ�
                                             ,carry_payment_slip_num                                       --�J�z���x���`�[�ԍ�
                                             ,report_decision_flag                                         --����m��t���O
                                             ,gl_interface_id                                              --GL�A�gID
                                             ,cancel_gl_interface_id                                       --���GL�A�gID
                                             ,created_by                                                   --�쐬��
                                             ,creation_date                                                --�쐬��
                                             ,last_updated_by                                              --�ŏI�X�V��
                                             ,last_update_date                                             --�ŏI�X�V��
                                             ,last_update_login                                            --�ŏI�X�V���O�C��
                                             ,request_id                                                   --�v��ID
                                             ,program_application_id                                       --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                                             ,program_id                                                   --�R���J�����g�E�v���O����ID
                                             ,program_update_date                                          --�v���O�����X�V��
                                             )
            VALUES                           (
                                              xxcok_sales_deduction_s01.nextval                            --�̔��T��ID
                                             ,ln_from_base                                                 --�U�֌����_
                                             ,ln_to_base                                                   --�U�֐拒�_
                                             ,ln_from_customer                                             --�U�֌��ڋq�R�[�h
                                             ,ln_to_customer                                               --�U�֐�ڋq�R�[�h
                                             ,null                                                         --�T���p�`�F�[���R�[�h
                                             ,null                                                         --��ƃR�[�h
                                             ,gd_record_date                                               --�v���
                                             ,cv_source_category_u                                         --�쐬���敪
                                             ,null                                                         --�쐬������ID
                                             ,null                                                         --�T������ID
                                             ,lt_customer_trx_line_tab( i ).trx_number                     --�T���ԍ�
                                             ,null                                                         --�T���ڍ�ID
                                             ,gv_data_type                                                 --�f�[�^���
                                             ,cv_status_new                                                --�X�e�[�^�X
                                             ,gv_item_code_dummy_NT                                        --�i�ڃR�[�h
                                             ,null                                                         --�̔��P��
                                             ,null                                                         --�̔��P��
                                             ,null                                                         --�̔�����
                                             ,null                                                         --����{�̋��z
                                             ,null                                                         --�������Ŋz
                                             ,null                                                         --�T���P��
                                             ,null                                                         --�T���P��
                                             ,null                                                         --�T������
                                             ,ln_rec_amount_div * -1                                       --�T���z
                                             ,null                                                         --��U
                                             ,null                                                         --�≮�}�[�W��
                                             ,null                                                         --�g��
                                             ,null                                                         --�≮�}�[�W�����z
                                             ,lv_conv_tax_code                                             --�ŃR�[�h 
                                             ,lv_conv_tax_rate                                             --�ŗ�
                                             ,null                                                         --�������ŃR�[�h
                                             ,null                                                         --�������ŗ�
                                             ,ln_tax_amount_div * -1                                       --�T���Ŋz
                                             ,CASE WHEN lt_customer_trx_line_tab( i ).selling_trns_rate is not null
                                                   THEN lt_customer_trx_line_tab( i ).ship_to_past_sale_base_code
                                                   ELSE null
                                                   END                                                     --���l
                                             ,null                                                         --�\����No.
                                             ,'N'                                                          --GL�A�g�t���O
                                             ,null                                                         --GL�v�㋒�_
                                             ,null                                                         --GL�L����
                                             ,null                                                         --���J�o���f�[�^�ǉ������t
                                             ,null                                                         --���J�o���f�[�^�ǉ����v��ID
                                             ,null                                                         --���J�o���f�[�^�폜�����t
                                             ,null                                                         --���J�o���f�[�^�폜���v��ID
                                             ,'N'                                                          --����t���O
                                             ,null                                                         --������v�㋒�_
                                             ,null                                                         --���GL�L����
                                             ,null                                                         --������{���[�U
                                             ,null                                                         --�������v�㋒�_
                                             ,lt_customer_trx_line_tab( i ).trx_number                     --�x���`�[�ԍ�
                                             ,lt_customer_trx_line_tab( i ).trx_number                     --�J�z���x���`�[�ԍ�
                                             ,null                                                         --����m��t���O
                                             ,null                                                         --GL�A�gID
                                             ,null                                                         --���GL�A�gID
                                             ,cn_created_by                                                --�쐬��
                                             ,cd_creation_date                                             --�쐬��
                                             ,cn_last_updated_by                                           --�ŏI�X�V��
                                             ,cd_last_update_date                                          --�ŏI�X�V��
                                             ,cn_last_update_login                                         --�ŏI�X�V���O�C��
                                             ,cn_request_id                                                --�v��ID
                                             ,cn_program_application_id                                    --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                                             ,cn_program_id                                                --�R���J�����g�E�v���O����ID
                                             ,cd_program_update_date                                       --�v���O�����X�V��
                                             );
            -- ��������
            gn_normal_cnt := gn_normal_cnt + 1;
--
         END IF;
--
        --�u���[�N�L�[�ێ�
        lv_trx_number         := lt_customer_trx_line_tab( i ).trx_number;
        ln_line_number        := lt_customer_trx_line_tab( i ).line_number;
--
        --���ז��̕�����̎c�z��ێ�
        ln_rec_amount_div_rem := ln_rec_amount_div_rem - lt_customer_trx_line_tab( i ).rec_amount_div;
        ln_tax_amount_div_rem := ln_tax_amount_div_rem - lt_customer_trx_line_tab( i ).tax_amount_div;
--
      END LOOP out_trx_line_loop;
--
      lv_step := 'A-4';
--
      OPEN  tax_check_cur;
      FETCH tax_check_cur BULK COLLECT INTO lt_tax_check_tab;
      CLOSE tax_check_cur;
      -- ���������J�E���g
      gn_warn_tax_cnt := lt_tax_check_tab.COUNT;
--
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                                 cv_appl_name_xxcok
                               , cv_msg_xxcok_10799
                               );
--
      <<out_tax_check_loop>>
      FOR i IN 1..lt_tax_check_tab.COUNT LOOP
--
        FND_FILE.PUT_LINE(
                          which  => FND_FILE.OUTPUT
                         ,buff   => lv_errmsg || ' ����ԍ��F' || lt_tax_check_tab( i ).trx_number || ' ���הԍ��F' || lt_tax_check_tab( i ).line_number
                          );
--
      END LOOP out_trx_line_loop;
--
      IF gn_warn_tax_cnt > 0 THEN
          ov_retcode := cv_status_warn;
      END IF;
--
      COMMIT;
--
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    -- *** �T�u�v���O������O�n���h�� ****
    WHEN subproc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[�����o��
      gn_error_cnt := gn_target_cnt;
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode   := cv_status_error;
--
--####################################  �Œ蕔 END   ###################s#######################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  --
  PROCEDURE main(
    errbuf         OUT    VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
   ,retcode        OUT    VARCHAR2         --   �G���[�R�[�h     #�Œ�#
  )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'main';               -- �v���O������
    cv_log                    CONSTANT VARCHAR2(100) := 'LOG';                -- ���O
    cv_output                 CONSTANT VARCHAR2(100) := 'OUTPUT';             -- �A�E�g�v�b�g
    cv_app_name_xxccp         CONSTANT VARCHAR2(100) := 'XXCCP';              -- �A�v���P�[�V�����Z�k��
    cv_target_cnt_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';   -- �Ώی������b�Z�[�W
    cv_success_cnt_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';   -- �����������b�Z�[�W
    cv_msg_ccp_90003          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90003';   -- �X�L�b�v�������b�Z�[�W
    cv_error_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';   -- �G���[�������b�Z�[�W
    cv_normal_msg             CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';   -- ����I�����b�Z�[�W
    cv_warn_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';   -- �x���I�����b�Z�[�W
    cv_error_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10008';   -- �G���[�I�����b�Z�[�W
    cv_token_name1            CONSTANT VARCHAR2(100) := 'COUNT';              -- ��������
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step                   VARCHAR2(10);                                   -- �X�e�b�v
    lv_message_code           VARCHAR2(100);                                  -- ���b�Z�[�W�R�[�h
--
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
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
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
       ov_errbuf      => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode     => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg      => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�G���[���b�Z�[�W
      );
--
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
   -- �ΏۂȂ��̏ꍇ
   IF gn_target_cnt = 0 THEN
      lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         cv_appl_name_xxcok
                       , cv_msg_xxcok_00001
                       );
      --�G���[�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg --0�����b�Z�[�W
       );
--
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg --0�����b�Z�[�W
       );
   END IF;
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_target_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt + gn_warn_tax_cnt - gn_rate_skip_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_success_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_ccp_90003
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_warn_tax_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_error_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOK024A39C;
/
