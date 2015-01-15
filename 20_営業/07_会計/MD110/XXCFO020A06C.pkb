CREATE OR REPLACE PACKAGE BODY  APPS.XXCFO020A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCFO020A06C (spec)
 * Description      : ���ǉ�v�d��Ȗڃ}�b�s���O���ʋ@�\
 * MD.050           : ���ǉ�v�d��Ȗڃ}�b�s���O���ʋ@�\ (MD050_CFO_020A06)
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 ���ǉ�v�d��Ȗڃ}�b�s���O���ʋ@�\
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/09/26    1.0   T.Kobori         �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO020A06C';              -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcfo          CONSTANT VARCHAR2(10)  := 'XXCFO';                     -- XXCFO
--
  /**********************************************************************************
   * Procedure Name   : get_siwake_account_title
   * Description      : ���ǉ�v�d��Ȗڃ}�b�s���O���ʋ@�\
   ***********************************************************************************/
  PROCEDURE get_siwake_account_title(
    ov_retcode                OUT    VARCHAR2      -- ���^�[���R�[�h
   ,ov_errbuf                 OUT    VARCHAR2      -- �G���[���b�Z�[�W
   ,ov_errmsg                 OUT    VARCHAR2      -- ���[�U�[�E�G���[���b�Z�[�W
   ,ov_company_code           OUT    VARCHAR2      -- 1.���
   ,ov_department_code        OUT    VARCHAR2      -- 2.����
   ,ov_account_title          OUT    VARCHAR2      -- 3.����Ȗ�
   ,ov_account_subsidiary     OUT    VARCHAR2      -- 4.�⏕�Ȗ�
   ,ov_description            OUT    VARCHAR2      -- 5.�E�v
   ,iv_report                 IN     VARCHAR2      -- 6.���[
   ,iv_class_code             IN     VARCHAR2      -- 7.�i�ڋ敪
   ,iv_prod_class             IN     VARCHAR2      -- 8.���i�敪
   ,iv_reason_code            IN     VARCHAR2      -- 9.���R�R�[�h
   ,iv_ptn_siwake             IN     VARCHAR2      -- 10.�d��p�^�[��
   ,iv_line_no                IN     VARCHAR2      -- 11.�s�ԍ�
   ,iv_gloif_dr_cr            IN     VARCHAR2      -- 12.�ؕ��E�ݕ�
   ,iv_warehouse_code         IN     VARCHAR2      -- 13.�q�ɃR�[�h
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_siwake_account_title'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_enabled_flag_enabled        CONSTANT VARCHAR2(1)   := 'Y';                           -- �Q�ƃ^�C�v�̗L���t���O�u�L���v
    cv_department                  CONSTANT VARCHAR2(100) := 'DEPARTMENT%';                 -- �Q�ƃ^�C�v(���I���哱�o�\)�̒��o����
    cv_others                      CONSTANT VARCHAR2(100) := 'OTHERS';                      -- �Q�ƃ^�C�v(���I���哱�o�\)�̒��o����
    -- ���b�Z�[�WID
    cv_msg_cfo_00001               CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00001';         --�v���t�@�C�����擾�G���[���b�Z�[�W
    cv_msg_cfo_10049               CONSTANT VARCHAR2(100) := 'APP-XXCFO1-10049';         -- �Ώۃf�[�^�Ȃ��G���[
    cv_msg_cfo_10050               CONSTANT VARCHAR2(100) := 'APP-XXCFO1-10050';         -- �Ώۃf�[�^��������G���[
    cv_msg_cfo_10051               CONSTANT VARCHAR2(100) := 'APP-XXCFO1-10051';         -- ���I���哱�o�\�Ώۃf�[�^��������G���[
    -- �g�[�N��
    cv_tkn_report                  CONSTANT VARCHAR2(100) := 'REPORT';
    cv_tkn_hinmoku                 CONSTANT VARCHAR2(100) := 'HINMOKU';
    cv_tkn_shohin                  CONSTANT VARCHAR2(100) := 'SHOHIN';
    cv_tkn_jiyuu                   CONSTANT VARCHAR2(100) := 'JIYUU';
    cv_tkn_siwake                  CONSTANT VARCHAR2(100) := 'SIWAKE';
    cv_tkn_gyou                    CONSTANT VARCHAR2(100) := 'GYOU';
    cv_tkn_taishaku                CONSTANT VARCHAR2(100) := 'TAISHAKU';
    cv_tkn_souko                   CONSTANT VARCHAR2(100) := 'SOUKO';
    cv_tkn_doutekibumon            CONSTANT VARCHAR2(100) := 'DOUTEKIBUMON';
    cv_tkn_attribute1              CONSTANT VARCHAR2(100) := 'ATTRIBUTE1';
    cv_tkn_attribute2_1            CONSTANT VARCHAR2(100) := 'ATTRIBUTE2_1';
    cv_tkn_attribute2_2            CONSTANT VARCHAR2(100) := 'ATTRIBUTE2_2';
    cv_tkn_prof_name               CONSTANT VARCHAR2(100) := 'PROF_NAME';
    -- �v���t�@�C��
    cv_prof_je_ptn_invoice         CONSTANT VARCHAR2(30)  := 'XXCFO1_JE_PTN_INVOICE';    -- XXCFO: �d��p�^�[���\
    cv_prof_je_dy_department       CONSTANT VARCHAR2(30)  := 'XXCFO1_JE_DY_DEPARTMENT';  -- XXCFO: ���I���咊�o�\
    cv_prof_je_ptn_rec_pay         CONSTANT VARCHAR2(30)  := 'XXCFO1_JE_PTN_REC_PAY';    -- XXCFO: �d��p�^�[��_�󕥎c���\
    cv_prof_je_ptn_rec_pay2        CONSTANT VARCHAR2(30)  := 'XXCFO1_JE_PTN_REC_PAY2';   -- XXCFO: �d��p�^�[��_�󕥎c���\2
    cv_prof_je_ptn_purchasing      CONSTANT VARCHAR2(30)  := 'XXCFO1_JE_PTN_PURCHASING'; -- XXCFO: �d��p�^�[��_�d�����ѕ\
    cv_prof_je_ptn_shipment        CONSTANT VARCHAR2(30)  := 'XXCFO1_JE_PTN_SHIPMENT';   -- XXCFO: �d��p�^�[��_�o�׎��ѕ\
    --
    --�v���t�@�C���l�擾
    lv_je_ptn_invoice              fnd_profile_option_values.profile_option_value%TYPE;
    lv_je_dy_department            fnd_profile_option_values.profile_option_value%TYPE;
    lv_je_ptn_rec_pay              fnd_profile_option_values.profile_option_value%TYPE;
    lv_je_ptn_rec_pay2             fnd_profile_option_values.profile_option_value%TYPE;
    lv_je_ptn_purchasing           fnd_profile_option_values.profile_option_value%TYPE;
    lv_je_ptn_shipment             fnd_profile_option_values.profile_option_value%TYPE;
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
    /*************************************
     *  �v���t�@�C���擾(A-1)            *
     *************************************/
    --
    -- XXCFO: �d��p�^�[���\
    lv_je_ptn_invoice    :=  fnd_profile.value( cv_prof_je_ptn_invoice );
    --
    -- �G���[����
    -- �uXXCFO: �d��p�^�[���\�v�擾���s
    IF ( lv_je_ptn_invoice    IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxccp,
                                            cv_msg_cfo_00001,
                                            cv_tkn_prof_name,
                                            cv_prof_je_ptn_invoice);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- XXCFO: ���I���咊�o
    lv_je_dy_department    :=  fnd_profile.value( cv_prof_je_dy_department );
    --
    -- �G���[����
    -- �uXXCFO: ���I���咊�o�v�擾���s
    IF ( lv_je_dy_department    IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxccp,
                                            cv_msg_cfo_00001,
                                            cv_tkn_prof_name,
                                            cv_prof_je_dy_department);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- XXCFO: �d��p�^�[��_�󕥎c���\
    lv_je_ptn_rec_pay    :=  fnd_profile.value( cv_prof_je_ptn_rec_pay );
    --
    -- �G���[����
    -- �uXXCFO: �d��p�^�[��_�󕥎c���\�v�擾���s
    IF ( lv_je_ptn_rec_pay    IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxccp,
                                            cv_msg_cfo_00001,
                                            cv_tkn_prof_name,
                                            cv_prof_je_ptn_rec_pay);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- XXCFO: �d��p�^�[��_�󕥎c���\2
    lv_je_ptn_rec_pay2    :=  fnd_profile.value( cv_prof_je_ptn_rec_pay2 );
    --
    -- �G���[����
    -- �uXXCFO: �d��p�^�[��_�󕥎c���\2�v�擾���s
    IF ( lv_je_ptn_rec_pay2    IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxccp,
                                            cv_msg_cfo_00001,
                                            cv_tkn_prof_name,
                                            cv_prof_je_ptn_rec_pay2);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- XXCFO: �d��p�^�[��_�d�����ѕ\
    lv_je_ptn_purchasing    :=  fnd_profile.value( cv_prof_je_ptn_purchasing );
    --
    -- �G���[����
    -- �uXXCFO: �d��p�^�[��_�d�����ѕ\�v�擾���s
    IF ( lv_je_ptn_purchasing    IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxccp,
                                            cv_msg_cfo_00001,
                                            cv_tkn_prof_name,
                                            cv_prof_je_ptn_purchasing);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- XXCFO: �d��p�^�[��_�o�׎��ѕ\
    lv_je_ptn_shipment    :=  fnd_profile.value( cv_prof_je_ptn_shipment );
    --
    -- �G���[����
    -- �uXXCFO: �d��p�^�[��_�o�׎��ѕ\�v�擾���s
    IF ( lv_je_ptn_shipment    IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxccp,
                                            cv_msg_cfo_00001,
                                            cv_tkn_prof_name,
                                            cv_prof_je_ptn_shipment);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
--
    /*************************************
     *  �d��p�^�[���\����̒��o (A-2)   *
     *************************************/
    --
    BEGIN
        --�d��p�^�[���\�擾SQL
        SELECT flvv.attribute8,         -- ���
               flvv.attribute9,         -- ����
               flvv.attribute10,        -- ����Ȗ�
               flvv.attribute11,        -- �⏕�Ȗ�
               flvv.attribute12         -- �E�v
        INTO   ov_company_code,
               ov_department_code,
               ov_account_title,
               ov_account_subsidiary,
               ov_description
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type  = lv_je_ptn_invoice        --�d��p�^�[���\
          AND    flvv.attribute1   = iv_report                --���[
          AND    flvv.attribute2   = iv_class_code            --�i�ڋ敪
--
          AND ((iv_report = lv_je_ptn_rec_pay                 --���[�F�󕥎c���\1
              AND    flvv.attribute3   = iv_prod_class        --���i�敪
              AND    flvv.attribute5   = iv_ptn_siwake        --�d��p�^�[��
              AND    flvv.attribute7   = iv_gloif_dr_cr       --�ؕ��E�ݕ�
              )
          OR  (iv_report = lv_je_ptn_rec_pay2                 --���[�F�󕥎c���\2
              AND    flvv.attribute3   = iv_prod_class        --���i�敪
              AND    flvv.attribute4   = iv_reason_code       --���R
              AND    flvv.attribute5   = iv_ptn_siwake        --�d��p�^�[��
              AND    flvv.attribute7   = iv_gloif_dr_cr       --�ؕ��E�ݕ�
              )
          OR  ((iv_report = lv_je_ptn_purchasing              --�d�����ѕ\�܂��͏o�׎��ѕ\
              OR iv_report = lv_je_ptn_shipment)
              AND    flvv.attribute5   = iv_ptn_siwake        --�d��p�^�[��
              AND    flvv.attribute6   = iv_line_no           --�s�ԍ�
              ))
--
          AND    TRUNC( SYSDATE ) BETWEEN TRUNC( NVL( flvv.start_date_active, SYSDATE ) )
                                  AND     TRUNC( NVL( flvv.end_date_active, SYSDATE ) )
          AND    flvv.enabled_flag = cv_enabled_flag_enabled
        ;
--
    EXCEPTION
      WHEN  NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxcfo,
                                              cv_msg_cfo_10049,
                                              cv_tkn_report,
                                              iv_report,
                                              cv_tkn_hinmoku,
                                              iv_class_code,
                                              cv_tkn_shohin,
                                              iv_prod_class,
                                              cv_tkn_jiyuu,
                                              iv_reason_code,
                                              cv_tkn_siwake,
                                              iv_ptn_siwake,
                                              cv_tkn_gyou,
                                              iv_line_no,
                                              cv_tkn_taishaku,
                                              iv_gloif_dr_cr,
                                              cv_tkn_souko,
                                              iv_warehouse_code);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN  TOO_MANY_ROWS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxcfo,
                                              cv_msg_cfo_10050,
                                              cv_tkn_report,
                                              iv_report,
                                              cv_tkn_hinmoku,
                                              iv_class_code,
                                              cv_tkn_shohin,
                                              iv_prod_class,
                                              cv_tkn_jiyuu,
                                              iv_reason_code,
                                              cv_tkn_siwake,
                                              iv_ptn_siwake,
                                              cv_tkn_gyou,
                                              iv_line_no,
                                              cv_tkn_taishaku,
                                              iv_gloif_dr_cr,
                                              cv_tkn_souko,
                                              iv_warehouse_code);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN  OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    /*****************************************
     *  ���I���哱�o�\����̕���̒��o (A-3) *
     *****************************************/
    --�d��p�^�[���\���璊�o�������傪�uDEPARTMENT�v�̕�����ƑO����v����ꍇ
    IF ov_department_code LIKE cv_department THEN
        BEGIN
            --���I���哱�o�\�擾SQL
            SELECT flvv.attribute3              -- ����
            INTO   ov_department_code
            FROM   fnd_lookup_values_vl flvv
            WHERE  flvv.lookup_type  = lv_je_dy_department        --���I���哱�o�\
              AND    flvv.attribute1   = ov_department_code         --����
              AND    flvv.attribute2   = iv_warehouse_code          --�q�ɃR�[�h
              AND    TRUNC( SYSDATE ) BETWEEN TRUNC( NVL( flvv.start_date_active, SYSDATE ) )
                                      AND     TRUNC( NVL( flvv.end_date_active, SYSDATE ) )
              AND    flvv.enabled_flag = cv_enabled_flag_enabled
            ;
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
            --1��ڂ̏����ŕ��傪���o�ł��Ȃ��ꍇ�uOTHERS�v�̕�����ōČ������s��
            BEGIN
                --���I���哱�o�\�擾SQL
                SELECT flvv.attribute3          -- ����
                INTO   ov_department_code
                FROM   fnd_lookup_values_vl flvv
                WHERE  flvv.lookup_type  = lv_je_dy_department    --���I���哱�o�\
                  AND    flvv.attribute1   = ov_department_code     --����
                  AND    flvv.attribute2   = cv_others              --���̑�
                  AND    TRUNC( SYSDATE ) BETWEEN TRUNC( NVL( flvv.start_date_active, SYSDATE ) )
                                          AND     TRUNC( NVL( flvv.end_date_active, SYSDATE ) )
                  AND    flvv.enabled_flag = cv_enabled_flag_enabled
                ;
            EXCEPTION
              WHEN  NO_DATA_FOUND THEN
                ov_department_code := NULL;
              WHEN  TOO_MANY_ROWS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxcfo,
                                                      cv_msg_cfo_10051,
                                                      cv_tkn_doutekibumon,
                                                      lv_je_dy_department,
                                                      cv_tkn_attribute1,
                                                      ov_department_code,
                                                      cv_tkn_attribute2_1,
                                                      NULL,
                                                      cv_tkn_attribute2_2,
                                                      cv_others);
                lv_errbuf := lv_errmsg;
                RAISE global_api_expt;
              WHEN  OTHERS THEN
                RAISE global_api_others_expt;
            END;
          WHEN  TOO_MANY_ROWS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxcfo,
                                                  cv_msg_cfo_10051,
                                                  cv_tkn_doutekibumon,
                                                  lv_je_dy_department,
                                                  cv_tkn_attribute1,
                                                  ov_department_code,
                                                  cv_tkn_attribute2_1,
                                                  iv_warehouse_code,
                                                  cv_tkn_attribute2_2,
                                                  NULL);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          WHEN  OTHERS THEN
            RAISE global_api_others_expt;
        END;
    END IF;
--
    /*****************************************
     *  OUT�p�����[�^�Z�b�g            (A-4) *
     *****************************************/
    --
    ov_retcode                  := cv_status_normal;   -- ���^�[���R�[�h
    ov_errbuf                   := NULL;               -- �G���[���b�Z�[�W
    ov_errmsg                   := NULL;               -- ���[�U�[�E�G���[���b�Z�[�W
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_siwake_account_title;
--
END XXCFO020A06C;
/
