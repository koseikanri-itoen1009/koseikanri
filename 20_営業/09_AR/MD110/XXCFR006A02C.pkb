CREATE OR REPLACE PACKAGE BODY XXCFR006A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR006A02C(body)
 * Description      : HHT��������
 * MD.050           : MD050_CFR_006_A02_HHT��������
 * MD.070           : MD050_CFR_006_A02_HHT��������
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ���̓p�����[�^�l���O�o�͏���            (A-1)
 *  get_receipt_methods    p �x�����@�擾����                        (A-3)
 *  start_api              p API�N��                                 (A-4)
 *  delete_htt             p HHT�����f�[�^�_���폜����               (A-5)
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/02    1.00  SCS �_�� ����    ����쐬
 *  2009/07/23    1.1   SCS T.KANEDA     T3����Q0000837�Ή�
 *  2009/10/16    1.2   SCS T.KANEDA     T4����Q�Ή�
 *  2011/02/23    1.3   SCS Y.Nishino    [E_�{�ғ�_02246]�Ή�
 *                                       AR�������ɔ[�i�拒�_�R�[�h�Ɣ[�i��ڋq�R�[�h��ǉ�
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
  lock_expt             EXCEPTION;      -- ���b�N(�r�W�[)�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR006A02C';        -- �p�b�P�[�W��
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';
  cv_dict_cd         CONSTANT VARCHAR2(100) := 'CFR006A02001';        -- HHT�����e�[�u��
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_006a02_001  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00026';     -- �x�����@�擾�����G���[���b�Z�[�W
  cv_msg_006a02_002  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00033';     -- �����쐬API�G���[���b�Z�[�W
  cv_msg_006a02_003  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003';     -- ���b�N�G���[���b�Z�[�W
  cv_msg_006a02_004  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00017';     -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_006a02_005  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00057';     -- �f�[�^�X�V�G���[���b�Z�[�W
-- Add 2011.02.23 Ver1.3 Start
  cv_msg_006a02_006  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004';     -- �v���t�@�C���擾�G���[���b�Z�[�W
-- Add 2011.02.23 Ver1.3 End
--
-- �g�[�N��
  cv_tkn_account     CONSTANT VARCHAR2(15) := 'ACCOUNT_CODE';         -- �ڋq�R�[�h
  cv_tkn_kyoten      CONSTANT VARCHAR2(15) := 'KYOTEN_CODE';          -- ���_�R�[�h
  cv_tkn_class       CONSTANT VARCHAR2(15) := 'RECEIPT_CLASS';        -- �����敪
  cv_tkn_date        CONSTANT VARCHAR2(15) := 'RECEIPT_DATE';         -- ������
  cv_tkn_amount      CONSTANT VARCHAR2(15) := 'AMOUNT';               -- �����z
  cv_tkn_meathod     CONSTANT VARCHAR2(15) := 'RECEIPT_MEATHOD';      -- �x�����@
  cv_tkn_message     CONSTANT VARCHAR2(15) := 'MESSAGE';              -- X_MSG_DATA
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';                -- �e�[�u����
-- Add 2011.02.23 Ver1.3 Start
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';            -- �v���t�@�C����
-- Add 2011.02.23 Ver1.3 End
--
-- Add 2011.02.23 Ver1.3 Start
  --�v���t�@�C��
  cv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';               -- �c�ƒP��
-- Add 2011.02.23 Ver1.3 End
--
  -- �t�@�C���o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';               -- ���b�Z�[�W�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';                  -- ���O�o��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
-- Add 2011.02.23 Ver1.3 Start
  gn_org_id                   NUMBER;                                 -- �c�ƒP��
-- Add 2011.02.23 Ver1.3 End
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���̓p�����[�^�l���O�o�͏���(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf              OUT     VARCHAR2,         --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT     VARCHAR2,         --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT     VARCHAR2)         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --==============================================================
    --�R���J�����g�p�����[�^�o��
    --==============================================================
--
    -- �R���J�����g�p�����[�^�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- ���b�Z�[�W�o��
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ���O�o��
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
-- Add 2011.02.23 Ver1.3 Start
    --==============================================================
    -- �v���t�@�C���l�̎擾
    --==============================================================
    -- �v���t�@�C������c�ƒP�ʎ擾
    gn_org_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- �擾�G���[��
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_006a02_006 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))  -- �c�ƒP��
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
-- Add 2011.02.23 Ver1.3 End
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
   * Procedure  Name   : get_receipt_methods
   * Description      : �x�����@�擾���� (A-3)
   ***********************************************************************************/
  Procedure get_receipt_methods(
    iv_base_code            IN         VARCHAR2,            -- ���_�R�[�h
    iv_customer_number      IN         VARCHAR2,            -- �ڋq�R�[�h
    in_payment_amount       IN         NUMBER,              -- �����z
    id_payment_date         IN         DATE,                -- ������
    iv_payment_class        IN         VARCHAR2,            -- �����敪
    ov_receipt_method_id    OUT        VARCHAR2,            -- �x�����@ID
-- Modify 2009.07.23 Ver1.1 Start
    ov_receipt_name         OUT        VARCHAR2,            -- �x�����@��
-- Modify 2009.07.23 Ver1.1 End
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_receipt_methods'; -- �v���O������
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
    lt_receipt_method_id ar_receipt_methods.receipt_method_id%TYPE;  -- �x�����@ID
    lt_name              ar_receipt_methods.name%TYPE;               -- ����
--
    -- *** ���[�J���E�J�[�\�� ***
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
    BEGIN
      -- ���o
      SELECT ar.receipt_method_id receipt_method_id,
             ar.name              name
      INTO lt_receipt_method_id,
           lt_name
      FROM ar_receipt_methods ar
      WHERE ar.attribute1 = iv_base_code      -- ���_�R�[�h
        AND ar.attribute2 = iv_payment_class  -- �����敪
      ;
--
      -- �x�����@ID�Z�b�g
      ov_receipt_method_id := lt_receipt_method_id;
-- Modify 2009.07.23 Ver1.1 Start
      ov_receipt_name := lt_name;
-- Modify 2009.07.23 Ver1.1 End
--
    EXCEPTION
      WHEN OTHERS THEN  -- �擾���G���[
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                 cv_msg_kbn_cfr     -- 'XXCFR'
                                ,cv_msg_006a02_001
                                ,cv_tkn_account     -- �g�[�N��'ACCOUNT_CODE'
                                ,iv_customer_number
                                   -- �ڋq�R�[�h
                                ,cv_tkn_kyoten      -- �g�[�N��'KYOTEN_CODE'
                                ,iv_base_code
                                   -- ���_�R�[�h
                                ,cv_tkn_class       -- �g�[�N��'RECEIPT_CLASS'
                                ,iv_payment_class
                                   -- �����敪
                                ,cv_tkn_date        -- �g�[�N��'RECEIPT_DATE'
                                ,TO_CHAR(id_payment_date, 'YYYY/MM/DD')
                                   -- ������
                                ,cv_tkn_amount      -- �g�[�N��'AMOUNT'
                                ,in_payment_amount
                              )    -- �����z
                             ,1
                             ,5000
                            );
--
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
        -- �x���Z�b�g
        ov_retcode := cv_status_warn;
    END;
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
  END get_receipt_methods;
--
  /**********************************************************************************
   * Procedure Name   : start_api
   * Description      : API�N�� (A-4)
   ***********************************************************************************/
  PROCEDURE start_api(
    in_payment_amount  IN  NUMBER,     -- �����z
    in_customer_number IN  VARCHAR2,   -- �ڋq�R�[�h
    in_cust_account_id IN  NUMBER,     -- �ڋqID
    in_receipt_id      IN  NUMBER,     -- �x�����@ID
-- Modify 2009.07.23 Ver1.1 Start
    in_receipt_name    IN  VARCHAR2,   -- �x�����@ID
-- Modify 2009.07.23 Ver1.1 End
    id_payment_date    IN  DATE,       -- ������
-- Add 2011.02.23 Ver1.3 Start
    iv_base_code                 IN  VARCHAR2,  -- ���_�R�[�h
    iv_delivery_customer_number  IN  VARCHAR2,  -- �[�i��ڋq�R�[�h
-- Add 2011.02.23 Ver1.3 End
    ov_errbuf          OUT VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_api'; -- �v���O������
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
    ln_cr_id            NUMBER;
    lv_return_status    VARCHAR2(1);
    ln_msg_count        NUMBER;
    lv_msg_data         VARCHAR2(2000);
-- Add 2011.02.23 Ver1.3 Start
    l_attribute_rec     ar_receipt_api_pub.attribute_rec_type  :=  NULL;  -- attribute�p
-- Add 2011.02.23 Ver1.3 End
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
    ov_errbuf  := lv_errbuf;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- =====================================================
    --  API�N�� (A-4)
    -- =====================================================
-- Add 2011.02.23 Ver1.3 Start
    -- �t���t���b�N�X�t�B�[���h�̐ݒ�
    l_attribute_rec.attribute_category := TO_CHAR(gn_org_id);           -- �c�ƒP��
    l_attribute_rec.attribute2         := iv_base_code;                 -- ���_�R�[�h
    l_attribute_rec.attribute3         := iv_delivery_customer_number;  -- �[�i��ڋq�R�[�h
-- Add 2011.02.23 Ver1.3 End
--
    --Call API
    ar_receipt_api_pub.create_cash( 
       p_api_version          =>  1.0
      ,p_init_msg_list        =>  fnd_api.g_true
      ,x_return_status        =>  lv_return_status
      ,x_msg_count            =>  ln_msg_count
      ,x_msg_data             =>  lv_msg_data
      ,p_amount               =>  in_payment_amount
      ,p_customer_id          =>  in_cust_account_id
      ,p_receipt_method_id    =>  in_receipt_id
      ,p_receipt_date         =>  id_payment_date
      ,p_gl_date              =>  id_payment_date
      ,p_cr_id                =>  ln_cr_id
-- Add 2011.02.23 Ver1.3 Start
      ,p_attribute_rec        =>  l_attribute_rec           -- �t���t���b�N�X
-- Add 2011.02.23 Ver1.3 End
    );
--
    IF (lv_return_status <> 'S') THEN
      --�G���[����
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                               cv_msg_kbn_cfr     -- 'XXCFR'
                              ,cv_msg_006a02_002
                              ,cv_tkn_account     -- �g�[�N��'ACCOUNT_CODE'
                              ,in_customer_number
                                 -- �ڋq�R�[�h
                              ,cv_tkn_meathod     -- �g�[�N��'RECEIPT_MEATHOD'
-- Modify 2009.07.23 Ver1.1 Start
--                              ,in_customer_number
                              ,in_receipt_name
-- Modify 2009.07.23 Ver1.1 End
                                 -- �x�����@
                              ,cv_tkn_date        -- �g�[�N��'RECEIPT_DATE'
                              ,TO_CHAR(id_payment_date, 'YYYY/MM/DD')
                                 -- ������
                              ,cv_tkn_amount      -- �g�[�N��'AMOUNT'
                              ,in_payment_amount
                            )    -- �����z
                           ,1
                           ,5000
                          );
      -- �����쐬API�G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
--
      -- API�W���G���[���b�Z�[�W�o��
      IF (ln_msg_count = 1) THEN
        -- API�W���G���[���b�Z�[�W���P���̏ꍇ
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '�E' || lv_msg_data
        );
--
      ELSE
        -- API�W���G���[���b�Z�[�W���������̏ꍇ
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '�E' || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_FIRST, FND_API.G_FALSE)
                                       ,1
                                       ,5000
                                     )
        );
        ln_msg_count := ln_msg_count - 1;
        
        <<while_loop>>
        WHILE ln_msg_count > 0 LOOP
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => '�E' || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE)
                                         ,1
                                         ,5000
                                       )
          );
          
          ln_msg_count := ln_msg_count - 1;
          
        END LOOP while_loop;
--
      END IF;
      -- �x���Z�b�g
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
  END start_api;
--
  /**********************************************************************************
   * Procedure Name   : delete_htt
   * Description      : HHT�����f�[�^�_���폜���� (A-5)
   ***********************************************************************************/
  PROCEDURE delete_htt(
    iv_base_code            IN         VARCHAR2,            -- ���_�R�[�h
    id_payment_date         IN         DATE,                -- ������
    iv_payment_class        IN         VARCHAR2,            -- �����敪
-- Add 2011.02.23 Ver1.3 Start
    iv_delivery_to_base_code  IN       VARCHAR2,            -- ���_�R�[�h
-- Add 2011.02.23 Ver1.3 End
    iv_customer_number      IN         VARCHAR2,            -- �ڋq�R�[�h
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_htt'; -- �v���O������
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
    -- ���o
    CURSOR lock_payment_cur(lt_base_code       xxcos_payment.base_code%TYPE,
                            lt_payment_date    xxcos_payment.payment_date%TYPE,
                            lt_payment_class   xxcos_payment.payment_class%TYPE,
                            lt_customer_number xxcos_payment.customer_number%TYPE)
    IS
      SELECT 'X'
      FROM xxcos_payment pay
      WHERE pay.base_code       = lt_base_code        -- ���_�R�[�h
        AND pay.payment_date    = lt_payment_date     -- ������
        AND pay.payment_class   = lt_payment_class    -- �����敪
        AND pay.customer_number = lt_customer_number  -- �ڋq�R�[�h
      FOR UPDATE NOWAIT
    ;
--
    lock_payment_rec lock_payment_cur%ROWTYPE;
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
    -- �J�[�\���I�[�v��
    OPEN lock_payment_cur( iv_base_code
                          ,id_payment_date
                          ,iv_payment_class
                          ,iv_customer_number
                         );
--
    -- �f�[�^�̎擾
    FETCH lock_payment_cur INTO lock_payment_rec;
--
    -- �J�[�\���N���[�Y
    CLOSE lock_payment_cur;
--
    -- HHT�����e�[�u���_���폜
    UPDATE xxcos_payment
    SET    delete_flag      = 'Y'
          ,last_updated_by  = cn_last_updated_by
          ,last_update_date = cd_last_update_date
    WHERE  base_code        = iv_base_code        -- ���_�R�[�h
    AND    payment_date     = id_payment_date     -- ������
    AND    payment_class    = iv_payment_class    -- �����敪
-- Modify 2011.02.23 Ver1.3 Start
---- Modify 2009.10.16 Ver1.2 Start
----    AND    customer_number  = iv_customer_number  -- �ڋq�R�[�h
--    AND    customer_number  in ( SELECT xchv.ship_account_number  -- �ڋq�R�[�h
--                                   FROM xxcfr_cust_hierarchy_v xchv
--                                  WHERE iv_customer_number = xchv.cash_account_number
--                                 UNION ALL
--                                 SELECT iv_customer_number  -- �ڋq�R�[�h
--                                   FROM DUAL
--                                )
---- Modify 2009.10.16 Ver1.2 End
    AND    NVL( delivery_to_base_code , base_code )  = iv_delivery_to_base_code  -- ���_�R�[�h
    AND    customer_number                           = iv_customer_number        -- �ڋq�R�[�h
-- Modify 2011.02.23 Ver1.3 End
    AND    delete_flag      = 'N'                 -- �폜�t���O
    ;
--
  EXCEPTION
    WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                               cv_msg_kbn_cfr       -- 'XXCFR'
                              ,cv_msg_006a02_003    -- �e�[�u�����b�N�G���[
                              ,cv_tkn_table         -- �g�[�N��'TABLE'
                              ,xxcfr_common_pkg.lookup_dictionary(
                                 cv_msg_kbn_cfr
                                ,cv_dict_cd
                               )                    -- 'HHT�����e�[�u��'
                            )
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
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
      -- �e�[�u�����b�N�ȊO�̃G���[����
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                               cv_msg_kbn_cfr       -- 'XXCFR'
                              ,cv_msg_006a02_004    -- �e�[�u�����b�N�G���[
                              ,cv_tkn_table         -- �g�[�N��'TABLE'
                              ,xxcfr_common_pkg.lookup_dictionary(
                                 cv_msg_kbn_cfr
                                ,cv_dict_cd
                               )                    -- 'HHT�����e�[�u��'
                            )
                          ,1
                          ,5000
                          );
      ov_errmsg  := lv_errmsg;
--
  END delete_htt;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    on_target_cnt          OUT     NUMBER,           -- �Ώی���
    on_normal_cnt          OUT     NUMBER,           -- ��������
    on_error_cnt           OUT     NUMBER,           -- �G���[����
    ov_errbuf              OUT     VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT     VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT     VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lt_receipt_id  ar_receipt_methods.receipt_method_id%TYPE;  -- �x�����@ID
-- Modify 2009.07.23 Ver1.1 Start
    lt_receipt_name  ar_receipt_methods.name%TYPE;  -- �x�����@ID
-- Modify 2009.07.23 Ver1.1 End
    lv_warning_flg VARCHAR2(1) := 'N';                         -- �x���t���O
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
    -- ���o
-- Modify 2009.10.16 Ver1.2 Start
--    CURSOR payment_cur
--    IS
--      SELECT hht.base_code           base_code,
--             hht.customer_number     customer_number,
--             SUM(hht.payment_amount) payment_amount,
--             hht.payment_date        payment_date,
--             hht.payment_class       payment_class,
--             cus.cust_account_id     cust_account_id
--      FROM xxcos_payment    hht,
--           hz_cust_accounts cus
--      WHERE hht.customer_number = cus.account_number(+)  -- �ڋq�R�[�h
--        AND hht.delete_flag     = 'N'                    -- �폜�t���O
--      GROUP BY hht.base_code
--              ,hht.customer_number
--              ,hht.payment_date
--              ,hht.payment_class
--              ,cus.cust_account_id
--    ;
--
--
-- ������ڋq�����݂���ꍇ�́A������ڋq���g�p����悤�ύX
    CURSOR payment_cur
    IS
      SELECT hht.base_code           base_code,
             NVL(xchv.cash_account_number,hht.customer_number)  customer_number,
             SUM(hht.payment_amount) payment_amount,
             hht.payment_date        payment_date,
             hht.payment_class       payment_class,
             NVL(xchv.cash_account_id,cus.cust_account_id)     cust_account_id
-- Add 2011.02.23 Ver1.3 Start
            ,NVL( hht.delivery_to_base_code , hht.base_code )  delivery_to_base_code
            ,hht.customer_number                               delivery_customer_number
-- Add 2011.02.23 Ver1.3 End
      FROM xxcos_payment    hht,
           hz_cust_accounts cus,
           xxcfr_cust_hierarchy_v xchv
      WHERE hht.customer_number = cus.account_number(+)         -- �ڋq�R�[�h
        AND hht.delete_flag     = 'N'                           -- �폜�t���O
        AND hht.customer_number = xchv.ship_account_number(+)   -- �ڋq�R�[�h
      GROUP BY hht.base_code
              ,NVL(xchv.cash_account_number,hht.customer_number)
              ,hht.payment_date
              ,hht.payment_class
              ,NVL(xchv.cash_account_id,cus.cust_account_id)
-- Add 2011.02.23 Ver1.3 Start
              ,NVL( hht.delivery_to_base_code , hht.base_code )
              ,hht.customer_number
-- Add 2011.02.23 Ver1.3 End
    ;
-- Modify 2009.10.16 Ver1.2 End
--
    payment_rec payment_cur%ROWTYPE;
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
    -- =====================================================
    --  ���̓p�����[�^�l���O�o�͏���(A-1)
    -- =====================================================
    init(
       lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  HHT�����f�[�^�擾����(A-2)
    -- =====================================================
--
    -- �J�[�\���I�[�v��
    OPEN payment_cur;
--
    <<payment_loop>>
    LOOP
      -- ���^�[���l������
      lv_retcode  := cv_status_normal;
--
    -- �f�[�^�̎擾
      FETCH payment_cur INTO payment_rec;
      EXIT WHEN payment_cur%NOTFOUND;
--
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- �ڋq�}�X�^���݃`�F�b�N
      IF (payment_rec.cust_account_id) IS NULL THEN
        --(�G���[����)
        -- �G���[�����J�E���g
        gn_error_cnt := gn_error_cnt + 1;
        lv_retcode  := cv_status_warn;
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                 cv_msg_kbn_cfr     -- 'XXCFR'
                                ,cv_msg_006a02_005
                                ,cv_tkn_account     -- �g�[�N��'ACCOUNT_CODE'
                                ,payment_rec.customer_number
                              )    -- �ڋq�R�[�h
                             ,1
                             ,5000
                            );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
      END IF;
--
    -- =====================================================
    --  �x�����@�擾���� (A-3)
    -- =====================================================
--
      -- ���폈���`�F�b�N
      IF (lv_retcode = cv_status_normal) THEN
        get_receipt_methods(
           payment_rec.base_code        -- ���_�R�[�h
          ,payment_rec.customer_number  -- �ڋq�R�[�h
          ,payment_rec.payment_amount   -- �����z
          ,payment_rec.payment_date     -- ������
          ,payment_rec.payment_class    -- �����敪
          ,lt_receipt_id                -- �x�����@ID
-- Modify 2009.07.23 Ver1.1 Start
          ,lt_receipt_name              -- �x�����@��
-- Modify 2009.07.23 Ver1.1 End
          ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
    -- =====================================================
    --  API�N�� (A-4)
    -- =====================================================
--
        -- ���폈���`�F�b�N
        IF (lv_retcode = cv_status_normal) THEN
          start_api(
             payment_rec.payment_amount   -- �����z
            ,payment_rec.customer_number  -- �ڋq�R�[�h
            ,payment_rec.cust_account_id  -- �ڋqID
            ,lt_receipt_id                -- �x�����@ID
-- Modify 2009.07.23 Ver1.1 Start
            ,lt_receipt_name              -- �x�����@��
-- Modify 2009.07.23 Ver1.1 End
            ,payment_rec.payment_date     -- ������
-- Add 2011.02.23 Ver1.3 Start
            ,payment_rec.delivery_to_base_code     -- ���_�R�[�h
            ,payment_rec.delivery_customer_number  -- �[�i��ڋq�R�[�h
-- Add 2011.02.23 Ver1.3 End
            ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
    -- =====================================================
    --  HHT�����f�[�^�_���폜���� (A-5)
    -- =====================================================
--
          -- ���폈���`�F�b�N
          IF (lv_retcode = cv_status_normal) THEN
            delete_htt(
               payment_rec.base_code       -- ���_�R�[�h
              ,payment_rec.payment_date    -- ������
              ,payment_rec.payment_class   -- �����敪
-- Modify 2011.02.23 Ver1.3 Start
--              ,payment_rec.customer_number -- �ڋq�R�[�h
              ,payment_rec.delivery_to_base_code     -- �[�i�拒�_�R�[�h
              ,payment_rec.delivery_customer_number  -- �[�i��ڋq�R�[�h
-- Modify 2011.02.23 Ver1.3 End
              ,lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF (lv_retcode = cv_status_error) THEN
              --(�G���[����)
              RAISE global_process_expt;
            END IF;
--
            -- ���������J�E���g
            gn_normal_cnt := gn_normal_cnt + 1;
--
          ELSE
            --(�G���[����)
            -- �G���[�����J�E���g
            gn_error_cnt := gn_error_cnt + 1;
          END IF;
        ELSE
          --(�G���[����)
          -- �G���[�����J�E���g
          gn_error_cnt := gn_error_cnt + 1;
        END IF;
      END IF;
--
    END LOOP payment_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE payment_cur;
--
    -- =====================================================
    --  �I������ (A-6)
    -- =====================================================
   on_target_cnt := gn_target_cnt;  -- �Ώی����J�E���g
   on_normal_cnt := gn_normal_cnt;  -- ���������J�E���g
   on_error_cnt  := gn_error_cnt;   -- �G���[�����J�E���g
--
   -- �x���t���O����
   IF (gn_error_cnt > 0) THEN
     ov_retcode := cv_status_warn;
   END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
-- Add Start 2008/12/16 SCS R.Hamanaka �e���v���[�g���C��
      IF (payment_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE payment_cur;
      END IF;
-- Add End 2008/12/16 SCS R.Hamanaka �e���v���[�g���C��
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
-- Add Start 2008/12/16 SCS R.Hamanaka �e���v���[�g���C��
      IF (payment_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE payment_cur;
      END IF;
-- Add End 2008/12/16 SCS R.Hamanaka �e���v���[�g���C��
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
-- Add Start 2008/12/16 SCS R.Hamanaka �e���v���[�g���C��
      IF (payment_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE payment_cur;
      END IF;
-- Add End 2008/12/16 SCS R.Hamanaka �e���v���[�g���C��
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
    errbuf                 OUT     VARCHAR2,         --    �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                OUT     VARCHAR2)         --    �G���[�R�[�h        --# �Œ� #
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
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100);   --���b�Z�[�W�R�[�h
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
       gn_target_cnt -- �Ώی���
      ,gn_normal_cnt -- ��������
      ,gn_error_cnt  -- �G���[����
      ,lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
    ELSE
      gn_warn_cnt   := 0;
    END IF;
--
--
--###########################  �Œ蕔 START   #####################################################
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
END XXCFR006A02C;
/
