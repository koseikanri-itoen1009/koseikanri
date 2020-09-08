CREATE OR REPLACE PACKAGE BODY APPS.XXCCP001A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCCP001A02C(body)
 * Description      : �s���̔����ь��m
 * MD.070           : �s���̔����ь��m(MD070_IPO_CCP_001_A02)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/08/06    1.0   N.Koyama         [E_�{�ғ�_16546]�V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �x������
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
  cv_pkg_name        CONSTANT VARCHAR2(100)   := 'XXCCP001A02C'; -- �p�b�P�[�W��
  cv_appl_short_name CONSTANT VARCHAR2(10)    := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
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
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_process_date       IN  VARCHAR2      --   �Ɩ����t
   ,ov_errbuf             OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain';           -- �v���O������
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
    ld_date    DATE;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �s���̔����у��R�[�h�擾
    CURSOR main_cur
    IS
--  �̔����уw�b�_���z�s��
       SELECT  1                                          AS error_kind
              ,xseh.sales_exp_header_id                   AS sales_exp_header_id
              ,xseh.ship_to_customer_code                 AS ship_to_customer_code
              ,TO_CHAR(xseh.delivery_date,'YYYY/MM/DD')   AS delivery_date
              ,xseh.sale_amount_sum                       AS sale_amount_sum
              ,SUM(xsel.sale_amount)                      AS sale_amount_sum_l
              ,xseh.results_employee_code                 AS results_employee_code
         FROM xxcos_sales_exp_headers xseh
             ,xxcos_sales_exp_lines   xsel
        WHERE xseh.business_date = ld_date
          AND xseh.sales_exp_header_id = xsel.sales_exp_header_id
        GROUP BY 1
                ,xseh.sales_exp_header_id
                ,xseh.ship_to_customer_code
                ,TO_CHAR(xseh.delivery_date,'YYYY/MM/DD')
                ,xseh.sale_amount_sum
                ,xseh.results_employee_code
       HAVING xseh.sale_amount_sum <> SUM(xsel.sale_amount)     
       UNION ALL
--  �̔����уw�b�_���ю҃R�[�h�s��
       SELECT  2                                          AS error_kind
              ,xseh.sales_exp_header_id                   AS sales_exp_header_id
              ,xseh.ship_to_customer_code                 AS ship_to_customer_code
              ,TO_CHAR(xseh.delivery_date,'YYYY/MM/DD')   AS delivery_date
              ,NULL                                       AS sale_amount_sum
              ,NULL                                       AS sale_amount_sum_l
              ,xseh.results_employee_code                 AS results_employee_code
         FROM xxcos_sales_exp_headers xseh
       WHERE xseh.business_date = ld_date
         AND NOT EXISTS  (SELECT 1
                            FROM per_all_people_f pap
                           WHERE pap.employee_number  = xseh.results_employee_code
                             AND xseh.delivery_date BETWEEN pap.effective_start_date
                               AND  NVL( pap.effective_end_date, ld_date ))
      ;
    -- ���C���J�[�\�����R�[�h�^
    main_rec  main_cur%ROWTYPE;
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
    gn_error_cnt  := 0;
--
    -- ===============================
    -- init��
    -- ===============================
--
    IF ( iv_process_date IS NULL ) THEN
      ld_date := xxccp_common_pkg2.get_process_date;
    ELSE
      ld_date := TO_DATE(iv_process_date,'YYYY/MM/DD HH24:MI:SS');
    END IF;
    -- �����Ɩ����t�o��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => '�����Ɩ����t�F'|| TO_CHAR(ld_date,'YYYY/MM/DD')
    );
--
    -- ===============================
    -- ������
    -- ===============================
--
    -- �f�[�^���o��
    FOR main_rec IN main_cur LOOP
      --�����Z�b�g
      gn_error_cnt := gn_error_cnt + 1;
      --
      IF ( main_rec.error_kind = 1 )
      THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '�̔����уw�b�_�̍��v���z�Ɣ̔����і��ׂ̍��v���z����v���Ă��܂���B'     ||
                     ' �̔�����ID:'   || main_rec.sales_exp_header_id                           ||  -- �̔�����ID
                     ' �ڋq�R�[�h:'   || main_rec.ship_to_customer_code                         ||  -- �ڋq�R�[�h
                     ' �[�i��:'       || main_rec.delivery_date                                 ||  -- �[�i��
                     ' �w�b�_���z:'   || main_rec.sale_amount_sum                               ||  -- �w�b�_���z
                     ' ���׋��z���v:' || main_rec.sale_amount_sum_l                                 -- ���׋��z���v
        );
      ELSE
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '�̔����уw�b�_�̐��ю҃R�[�h���]�ƈ��}�X�^�ɑ��݂��܂���B'               ||
                     ' �̔�����ID:'   || main_rec.sales_exp_header_id                           ||  -- �̔�����ID
                     ' �ڋq�R�[�h:'   || main_rec.ship_to_customer_code                         ||  -- �ڋq�R�[�h
                     ' �[�i��:'       || main_rec.delivery_date                                 ||  -- �[�i��
                     ' ���ю҃R�[�h:' || main_rec.results_employee_code                             -- ���ю҃R�[�h
        );
      END IF;
    END LOOP;
    IF ( gn_error_cnt > 0 ) THEN
      ov_retcode := cv_status_error;
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
    errbuf                OUT VARCHAR2      --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode               OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
   ,iv_process_date       IN  VARCHAR2      --   �Ɩ����t
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
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
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
       iv_which   => 'LOG'
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
       iv_process_date                             -- �Ɩ����t
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
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
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
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
    ELSIF(lv_retcode = cv_status_error) THEN
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
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCCP001A02C;
/