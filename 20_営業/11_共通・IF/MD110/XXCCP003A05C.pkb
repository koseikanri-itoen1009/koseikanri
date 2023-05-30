CREATE OR REPLACE PACKAGE BODY APPS.XXCCP003A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCCP003A05C(body)
 * Description      : �s���T���x�����m
 * MD.070           : �s���T���x�����m(MD070_IPO_CCP_003_A05)
 * Version          : 1.3
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
 *  2022/03/15    1.0   K.Yoshikawa     [E_�{�ғ�_18075]�V�K�쐬
 *  2022/06/08    1.1   K.Yoshikawa     [E_�{�ғ�_18306]
 *  2022/08/02    1.2   SCSK Y.Koh      [E_�{�ғ�_18517]
 *  2023/05/25    1.3   K.Yoshikawa     [E_�{�ғ�_19244]
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
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
  cv_pkg_name        CONSTANT VARCHAR2(100)   := 'XXCCP003A05C'; -- �p�b�P�[�W��
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
    -- �� �T���������׏��iAP�\���j
    CURSOR main_cur1
    IS
       SELECT
           h.recon_base_code       recon_base_code        , --�x���������_       
           h.recon_slip_num        recon_slip_num         , --�x���`�[�ԍ�       
           h.recon_status          recon_status           , --�����X�e�[�^�X     
           h.applicant             applicant              , --�\����             
           h.application_date      application_date       , --�\����             
           h.approver              approver               , --���F��             
           h.approval_date         approval_date          , --���F��             
           h.payee_code            payee_code             , --�x����             
           h.invoice_date          invoice_date           , --���������t         
           h.recon_due_date        recon_due_date         , --�x���\���         
           h.interface_div         interface_div          , --�A�g��             
           h.gl_date               gl_date                , --GL�L����           
           h.corp_code             corp_code              , --����_���          
           h.deduction_chain_code  deduction_chain_code_c , --����_�T���p�`�F�[��
           h.cust_code             cust_code              , --����_�ڋq          
           h.condition_no          condition_no           , --����_�T���ԍ�      
           h.target_data_type      target_data_type       , --����_�Ώۃf�[�^���
           h.target_date_end       target_date_end        , --����_�Ώۊ���TO    
           h.invoice_number        invoice_number         , --����_��̐������ԍ�
           l.deduction_chain_code  deduction_chain_code   , --�T���p�`�F�[��     
           l.deduction_amt         deduction_amt          , --�T���z_�{�̊z      
           l.payment_amt           payment_amt            , --�x���z_�{�̊z      
           l.difference_amt        difference_amt         , --�������z_�{�̊z    
           l.deduction_tax         deduction_tax          , --�T���z_�Ŋz        
           l.payment_tax           payment_tax            , --�x���z_�Ŋz        
           l.difference_tax        difference_tax           --�������z_�Ŋz      
       FROM
           xxcok.xxcok_deduction_recon_line_ap l,
           xxcok.xxcok_deduction_recon_head    h
       WHERE
           h.recon_status                  NOT IN ('CD','DD')
       AND l.recon_slip_num                =   h.recon_slip_num
       AND l.last_update_date              >=  ld_date
       AND ( l.deduction_amt - l.payment_amt !=  l.difference_amt  OR  l.deduction_tax - l.payment_tax !=  l.difference_tax  );
    -- ���C���J�[�\�����R�[�h�^
    main_rec1  main_cur1%ROWTYPE;
--
    -- �� �T��No�ʏ������
    CURSOR main_cur2
    IS
       SELECT
           h.recon_base_code       recon_base_code        , --�x���������_        
           h.recon_slip_num        recon_slip_num         , --�x���`�[�ԍ�        
           h.recon_status          recon_status           , --�����X�e�[�^�X      
           h.applicant             applicant              , --�\����              
           h.application_date      application_date       , --�\����              
           h.approver              approver               , --���F��              
           h.approval_date         approval_date          , --���F��              
           h.payee_code            payee_code             , --�x����              
           h.invoice_date          invoice_date           , --���������t          
           h.recon_due_date        recon_due_date         , --�x���\���          
           h.interface_div         interface_div          , --�A�g��              
           h.gl_date               gl_date                , --GL�L����            
           h.corp_code             corp_code              , --����_���           
           h.deduction_chain_code  deduction_chain_code_c , --����_�T���p�`�F�[�� 
           h.cust_code             cust_code              , --����_�ڋq           
           h.condition_no          condition_no_c         , --����_�T���ԍ�       
           h.target_data_type      target_data_type       , --����_�Ώۃf�[�^��� 
           h.target_date_end       target_date_end        , --����_�Ώۊ���TO     
           h.invoice_number        invoice_number         , --����_��̐������ԍ� 
           l.deduction_chain_code  deduction_chain_code   , --�T���p�`�F�[��      
           l.condition_no          condition_no           , --�T���ԍ�            
           l.data_type             data_type              , --�f�[�^���          
           l.payment_tax_code      payment_tax_code       , --�x�����ŃR�[�h      
           l.deduction_amt         deduction_amt          , --�T���z_�{�̊z       
           l.payment_amt           payment_amt            , --�x���z_�{�̊z       
           l.difference_amt        difference_amt         , --�������z_�{�̊z     
           l.deduction_tax         deduction_tax          , --�T���z_�Ŋz         
           l.payment_tax           payment_tax            , --�x���z_�Ŋz         
           l.difference_tax        difference_tax           --�������z_�Ŋz       
       FROM
           xxcok.xxcok_deduction_num_recon   l,
           xxcok.xxcok_deduction_recon_head  h
       WHERE
           h.recon_status                  NOT IN ('CD','DD')
       AND l.recon_slip_num                =   h.recon_slip_num
       AND l.last_update_date              >=  ld_date
       AND ( l.deduction_amt - l.payment_amt !=  l.difference_amt  OR  l.deduction_tax - l.payment_tax !=  l.difference_tax  );
    -- ���C���J�[�\�����R�[�h�^
    main_rec2  main_cur2%ROWTYPE;
--
    -- �� �T���������׏��i�≮�����j
    CURSOR main_cur3
    IS
       SELECT
           h.recon_base_code       recon_base_code        , --�x���������_        
           h.recon_slip_num        recon_slip_num         , --�x���`�[�ԍ�        
           h.recon_status          recon_status           , --�����X�e�[�^�X      
           h.applicant             applicant              , --�\����              
           h.application_date      application_date       , --�\����              
           h.approver              approver               , --���F��              
           h.approval_date         approval_date          , --���F��              
           h.payee_code            payee_code             , --�x����              
           h.invoice_date          invoice_date           , --���������t          
           h.recon_due_date        recon_due_date         , --�x���\���          
           h.interface_div         interface_div          , --�A�g��              
           h.gl_date               gl_date                , --GL�L����            
           h.corp_code             corp_code              , --����_���           
           h.deduction_chain_code  deduction_chain_code_c , --����_�T���p�`�F�[�� 
           h.cust_code             cust_code              , --����_�ڋq           
           h.condition_no          condition_no           , --����_�T���ԍ�       
           h.target_data_type      target_data_type       , --����_�Ώۃf�[�^��� 
           h.target_date_end       target_date_end        , --����_�Ώۊ���TO     
           h.invoice_number        invoice_number         , --����_��̐������ԍ� 
           l.deduction_chain_code  deduction_chain_code   , --�T���p�`�F�[��      
           l.deduction_amt         deduction_amt          , --�T���z_�{�̊z       
           l.payment_amt           payment_amt            , --�x���z_�{�̊z       
           l.difference_amt        difference_amt         , --�������z_�{�̊z     
           l.deduction_tax         deduction_tax          , --�T���z_�Ŋz         
           l.payment_tax           payment_tax            , --�x���z_�Ŋz         
           l.difference_tax        difference_tax           --�������z_�Ŋz       
       FROM
           xxcok.xxcok_deduction_recon_line_wp l,
           xxcok.xxcok_deduction_recon_head    h
       WHERE
           h.recon_status                  NOT IN ('CD','DD')
       AND l.recon_slip_num                =   h.recon_slip_num
       AND l.last_update_date              >=  ld_date
       AND ( l.deduction_amt - l.payment_amt !=  l.difference_amt  OR  l.deduction_tax - l.payment_tax !=  l.difference_tax  );
    -- ���C���J�[�\�����R�[�h�^
    main_rec3  main_cur3%ROWTYPE;
--
    -- �� ���i�ʓˍ����
    CURSOR main_cur4
    IS
       SELECT
           h.recon_base_code       recon_base_code        , --�x���������_        
           h.recon_slip_num        recon_slip_num         , --�x���`�[�ԍ�        
           h.recon_status          recon_status           , --�����X�e�[�^�X      
           h.applicant             applicant              , --�\����              
           h.application_date      application_date       , --�\����              
           h.approver              approver               , --���F��              
           h.approval_date         approval_date          , --���F��              
           h.payee_code            payee_code             , --�x����              
           h.invoice_date          invoice_date           , --���������t          
           h.recon_due_date        recon_due_date         , --�x���\���          
           h.interface_div         interface_div          , --�A�g��              
           h.gl_date               gl_date                , --GL�L����            
           h.corp_code             corp_code              , --����_���           
           h.deduction_chain_code  deduction_chain_code_c , --����_�T���p�`�F�[�� 
           h.cust_code             cust_code              , --����_�ڋq           
           h.condition_no          condition_no           , --����_�T���ԍ�       
           h.target_data_type      target_data_type       , --����_�Ώۃf�[�^��� 
           h.target_date_end       target_date_end        , --����_�Ώۊ���TO     
           h.invoice_number        invoice_number         , --����_��̐������ԍ� 
           l.deduction_chain_code  deduction_chain_code   , --�T���p�`�F�[��      
           l.item_code             item_code              , --�i��                
           l.tax_code              tax_code               , --����ŃR�[�h        
           l.deduction_amt         deduction_amt          , --�T���z_�{�̊z       
           l.payment_amt           payment_amt            , --�x���z_�{�̊z       
           l.difference_amt        difference_amt         , --�������z_�{�̊z     
           l.deduction_tax         deduction_tax          , --�T���z_�Ŋz         
           l.payment_tax           payment_tax            , --�x���z_�Ŋz         
           l.difference_tax        difference_tax           --�������z_�Ŋz       
       FROM
           xxcok.xxcok_deduction_item_recon  l,
           xxcok.xxcok_deduction_recon_head  h
       WHERE
           h.recon_status                  NOT IN ('CD','DD')
       AND l.recon_slip_num                =   h.recon_slip_num
       AND l.last_update_date              >=  ld_date
       AND ( l.deduction_amt - l.payment_amt !=  l.difference_amt  OR  l.deduction_tax - l.payment_tax !=  l.difference_tax  );
    -- ���C���J�[�\�����R�[�h�^
    main_rec4  main_cur4%ROWTYPE;
--
    -- �� �T��No�ʏ������(�ςݏグ�s��)
    CURSOR main_cur5
    IS
       SELECT
           h.recon_base_code       recon_base_code        , --�x���������_        
           h.recon_slip_num        recon_slip_num         , --�x���`�[�ԍ�        
           h.recon_status          recon_status           , --�����X�e�[�^�X      
           h.applicant             applicant              , --�\����              
           h.application_date      application_date       , --�\����              
           h.approver              approver               , --���F��              
           h.approval_date         approval_date          , --���F��              
           h.payee_code            payee_code             , --�x����              
           h.invoice_date          invoice_date           , --���������t          
           h.recon_due_date        recon_due_date         , --�x���\���          
           h.interface_div         interface_div          , --�A�g��              
           h.gl_date               gl_date                , --GL�L����            
           h.corp_code             corp_code              , --����_���           
           h.deduction_chain_code  deduction_chain_code_c , --����_�T���p�`�F�[�� 
           h.cust_code             cust_code              , --����_�ڋq           
           h.condition_no          condition_no           , --����_�T���ԍ�       
           h.target_data_type      target_data_type       , --����_�Ώۃf�[�^��� 
           h.target_date_end       target_date_end        , --����_�Ώۊ���TO     
           h.invoice_number        invoice_number         , --����_��̐������ԍ� 
--2022/06/08 1.1 add start
           l.deduction_chain_code  deduction_chain_code   ,
--2022/06/08 1.1 add end
           l.deduction_amt         deduction_amt          ,
           l.deduction_tax         deduction_tax          ,
           l.payment_amt           payment_amt            ,
           l.payment_tax           payment_tax            ,
           l.difference_amt        difference_amt         ,
           l.difference_tax        difference_tax         ,
           SUM(n.payment_amt)      sum_payment_amt        ,
           SUM(n.payment_tax)      sum_payment_tax
       FROM
           xxcok.xxcok_deduction_num_recon     n,
           xxcok.xxcok_deduction_recon_head    h,
           xxcok.xxcok_deduction_recon_line_ap l
       WHERE
           h.recon_status                  NOT IN ('CD','DD')
       AND l.recon_slip_num                =   h.recon_slip_num
       AND l.last_update_date              >=  ld_date
       AND n.recon_slip_num                =   l.recon_slip_num
       AND nvl(n.deduction_chain_code,'-') = nvl(l.deduction_chain_code,'-')
       GROUP BY
           h.recon_base_code      ,
           h.recon_slip_num       ,
           h.recon_status         ,
           h.applicant            ,
           h.application_date     ,
           h.approver             ,
           h.approval_date        ,
           h.payee_code           ,
           h.invoice_date         ,
           h.recon_due_date       ,
           h.interface_div        ,
           h.gl_date              ,
           h.corp_code            ,
           h.deduction_chain_code ,
           h.cust_code            ,
           h.condition_no         ,
           h.target_data_type     ,
           h.target_date_end      ,
           h.invoice_number       ,
--2022/06/08 1.1 add start
           l.deduction_chain_code ,
--2022/06/08 1.1 add end
           l.deduction_amt        ,
           l.deduction_tax        ,
           l.payment_amt          ,
           l.payment_tax          ,
           l.difference_amt       ,
           l.difference_tax       
       HAVING
           l.payment_amt !=  sum(n.payment_amt)  OR  l.payment_tax !=  sum(n.payment_tax);
    -- ���C���J�[�\�����R�[�h�^
    main_rec5  main_cur5%ROWTYPE;
--
    -- �� ���i�ʏ������(�ςݏグ�s��)
    CURSOR main_cur6
    IS
       SELECT
           h.recon_base_code       recon_base_code        , --�x���������_        
           h.recon_slip_num        recon_slip_num         , --�x���`�[�ԍ�        
           h.recon_status          recon_status           , --�����X�e�[�^�X      
           h.applicant             applicant              , --�\����              
           h.application_date      application_date       , --�\����              
           h.approver              approver               , --���F��              
           h.approval_date         approval_date          , --���F��              
           h.payee_code            payee_code             , --�x����              
           h.invoice_date          invoice_date           , --���������t          
           h.recon_due_date        recon_due_date         , --�x���\���          
           h.interface_div         interface_div          , --�A�g��              
           h.gl_date               gl_date                , --GL�L����            
           h.corp_code             corp_code              , --����_���           
           h.deduction_chain_code  deduction_chain_code_c , --����_�T���p�`�F�[�� 
           h.cust_code             cust_code              , --����_�ڋq           
           h.condition_no          condition_no           , --����_�T���ԍ�       
           h.target_data_type      target_data_type       , --����_�Ώۃf�[�^��� 
           h.target_date_end       target_date_end        , --����_�Ώۊ���TO     
           h.invoice_number        invoice_number         , --����_��̐������ԍ� 
--2022/06/08 1.1 add start
           l.deduction_chain_code  deduction_chain_code   ,
--2022/06/08 1.1 add end
           l.deduction_amt         deduction_amt ,
           l.deduction_tax         deduction_tax ,
           l.payment_amt           payment_amt   ,
           l.payment_tax           payment_tax   ,
           l.difference_amt        difference_amt,
           l.difference_tax        difference_tax,
           sum(n.payment_amt)      sum_payment_amt,
           sum(n.payment_tax)      sum_payment_tax
       FROM
           xxcok.xxcok_deduction_item_recon    n,
           xxcok.xxcok_deduction_recon_head    h,
           xxcok.xxcok_deduction_recon_line_wp l
       WHERE
           h.recon_status                  NOT IN ('CD','DD')
       AND l.recon_slip_num                =   h.recon_slip_num
       AND l.last_update_date              >=  ld_date
       AND n.recon_slip_num                =   l.recon_slip_num
       AND n.deduction_chain_code          =   l.deduction_chain_code
       GROUP BY
           h.recon_base_code      ,
           h.recon_slip_num       ,
           h.recon_status         ,
           h.applicant            ,
           h.application_date     ,
           h.approver             ,
           h.approval_date        ,
           h.payee_code           ,
           h.invoice_date         ,
           h.recon_due_date       ,
           h.interface_div        ,
           h.gl_date              ,
           h.corp_code            ,
           h.deduction_chain_code ,
           h.cust_code            ,
           h.condition_no         ,
           h.target_data_type     ,
           h.target_date_end      ,
           h.invoice_number       ,
--2022/06/08 1.1 add start
           l.deduction_chain_code ,
--2022/06/08 1.1 add end
           l.deduction_amt        ,
           l.deduction_tax        ,
           l.payment_amt          ,
           l.payment_tax          ,
           l.difference_amt       ,
           l.difference_tax       
       HAVING
           l.payment_amt !=  sum(n.payment_amt)  OR  l.payment_tax !=  sum(n.payment_tax);
    -- ���C���J�[�\�����R�[�h�^
    main_rec6  main_cur6%ROWTYPE;
--
--2022/06/08 1.1 add start
    -- �� �̔��T�����ƍT��No�ʁA���i�ʂ̋��z�s��v���m
    CURSOR main_cur7
    IS
       SELECT
         h.creation_date                                                                                                        creation_date           ,--�쐬��
         h.deduction_recon_head_id                                                                                              deduction_recon_head_id ,--�T�������w�b�_�[ID
         h.recon_slip_num                                                                                                       recon_slip_num          ,--�x���`�[�ԍ�
         h.applicant                                                                                                            applicant               ,--�\����
         (SELECT nvl(description,h.applicant) FROM fnd_user fu WHERE fu.user_name = h.applicant)                                applicant_name          ,--�\����
         h.approver                                                                                                             approver                ,--���F��
         (SELECT nvl(description,h.approver) FROM fnd_user fu WHERE fu.user_name = h.approver)                                  approver_name           ,--���F��
         h.recon_due_date                                                                                                       recon_due_date          ,--�x���\���
         h.recon_base_code                                                                                                      recon_base_code         ,--�x���������_
         h.payee_code                                                                                                           payee_code              ,--�x����R�[�h
         h.recon_status                                                                                                         recon_status_code       ,--�����X�e�[�^�X�R�[�h
         decode(h.recon_status,'EG','���͒�','SG','���M��','SD','���M��','AD','���F��','CD','�����','DD','�폜��')             recon_status            ,--�����X�e�[�^�X
         h.corp_code                                                                                                            corp_code               ,--��ƃR�[�h
         h.deduction_chain_code                                                                                                 deduction_chain_code    ,--�T���p�`�F�[���R�[�h
         h.cust_code                                                                                                            cust_code               ,--�ڋq�R�[�h
         h.condition_no                                                                                                         condition_no            ,--�T���ԍ�
         h.target_date_end                                                                                                      target_date_end         ,--�Ώۊ���TO
         DECODE(h.interface_div,'AP','�T���x��','�≮�x��')                                                                     interface_div           ,--�A�g��
         (SELECT SUM(deduction_amt) from xxcok.xxcok_deduction_num_recon n where n.recon_slip_num = h.recon_slip_num)           n_deduction_amt         ,--�T��No��_�T���z
         (SELECT SUM(deduction_amt) from xxcok.xxcok_deduction_item_recon i where i.recon_slip_num = h.recon_slip_num)          i_deduction_amt         ,--�i�ڕ�_�T���z
         (SELECT SUM(deduction_amount) FROM xxcok.xxcok_sales_deduction s WHERE s.recon_slip_num = h.recon_slip_num AND s.status = 'N' AND s.source_category NOT IN ('D','O') AND s.created_by <> -1) 
                                                                                                                                s_deduction_amount      ,--�T���f�[�^_�T���z
         (SELECT NVL(SUM(deduction_amount),0) FROM xxcok.xxcok_sales_deduction s WHERE s.recon_slip_num = h.recon_slip_num AND S.STATUS = 'N' AND s.source_category NOT IN ('D','O') AND s.created_by <> -1)  -
          (SELECT NVL(SUM(deduction_amt),0) FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num) - 
          (SELECT NVL(SUM(deduction_amt),0) FROM xxcok.xxcok_deduction_item_recon i WHERE i.recon_slip_num = h.recon_slip_num)  deduction_amt_diff      ,--�T���z�ُ�l
         (SELECT SUM(deduction_tax) FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num)           n_deduction_tax         ,--�T��NO��_�Ŋz
         (SELECT SUM(deduction_tax) FROM xxcok.xxcok_deduction_item_recon i WHERE i.recon_slip_num = h.recon_slip_num)          i_deduction_tax         ,--�i�ڕ�_�Ŋz
         (SELECT SUM(deduction_tax_amount) FROM xxcok.xxcok_sales_deduction s WHERE s.recon_slip_num = h.recon_slip_num AND s.status = 'N' AND s.source_category NOT IN ('D','O') AND s.created_by <> -1) 
                                                                                                                                s_deduction_tax_amount  ,--�T���f�[�^_�Ŋz
         (SELECT NVL(SUM(deduction_tax_amount),0) FROM xxcok.xxcok_sales_deduction s WHERE s.recon_slip_num = h.recon_slip_num AND s.status = 'N' AND s.source_category NOT IN ('D','O') AND s.created_by <> -1)  -
          (SELECT NVL(SUM(deduction_tax),0) FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num) - 
          (SELECT NVL(SUM(deduction_tax),0) FROM xxcok.xxcok_deduction_item_recon i WHERE i.recon_slip_num = h.recon_slip_num)  deduction_tax_diff       --�Ŋz�ُ�l
       FROM  xxcok.xxcok_deduction_recon_head h
       WHERE h.recon_status  IN ('AD','EG','SD','SG')  
       AND (  h.last_update_date >= ld_date 
             OR
             (SELECT MAX(n.last_update_date) FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num) >= ld_date 
             OR
             (SELECT MAX(i.last_update_date) FROM xxcok.xxcok_deduction_item_recon i WHERE i.recon_slip_num = h.recon_slip_num) >= ld_date 
           )
       AND (  (SELECT NVL(SUM(deduction_amount),0) FROM xxcok.xxcok_sales_deduction s WHERE s.recon_slip_num = h.recon_slip_num AND S.STATUS = 'N' AND s.source_category NOT IN ('D','O') AND s.created_by <> -1)  -
              (SELECT NVL(SUM(deduction_amt),0) FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num) - 
              (SELECT NVL(SUM(deduction_amt),0) FROM xxcok.xxcok_deduction_item_recon i WHERE i.recon_slip_num = h.recon_slip_num) 
              <> 0
            OR
              (SELECT NVL(SUM(deduction_tax_amount),0) FROM xxcok.xxcok_sales_deduction s WHERE s.recon_slip_num = h.recon_slip_num AND s.status = 'N' AND s.source_category NOT IN ('D','O') AND s.created_by <> -1)  -
              (SELECT NVL(SUM(deduction_tax),0) FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num) - 
              (SELECT NVL(SUM(deduction_tax),0) FROM xxcok.xxcok_deduction_item_recon i WHERE i.recon_slip_num = h.recon_slip_num)
              <> 0
           );
    -- ���C���J�[�\�����R�[�h�^
    main_rec7  main_cur7%ROWTYPE;
--
    -- �� AP������͓`�[�X�e�[�^�X�����F�ςŁA�T�������w�b�_�[�̃X�e�[�^�X���폜�ς�
    CURSOR main_cur8
    IS
       SELECT  
         h.creation_date                                                                                                creation_date           , --�쐬��
         h.deduction_recon_head_id                                                                                      deduction_recon_head_id , --�T�������w�b�_�[ID
         h.recon_slip_num                                                                                               recon_slip_num          , --�x���`�[�ԍ�
         h.applicant                                                                                                    applicant               , --�\����
         (SELECT nvl(description,h.applicant) FROM fnd_user fu WHERE fu.user_name = h.applicant)                        applicant_name          , --�\����
         h.approver                                                                                                     approver                , --���F��
         (SELECT nvl(description,h.approver) FROM fnd_user fu WHERE fu.user_name = h.approver)                          approver_name           , --���F��
         h.recon_due_date                                                                                               recon_due_date          , --�x���\���
         h.recon_base_code                                                                                              recon_base_code         , --�x���������_
         h.payee_code                                                                                                   payee_code              , --�x����R�[�h
         h.recon_status                                                                                                 recon_status_code       , --�����X�e�[�^�X�R�[�h
         decode(h.recon_status,'EG','���͒�','SG','���M��','SD','���M��','AD','���F��','CD','�����','DD','�폜��')     recon_status            , --�����X�e�[�^�X
         h.corp_code                                                                                                    corp_code               , --��ƃR�[�h
         h.deduction_chain_code                                                                                         deduction_chain_code    , --�T���p�`�F�[���R�[�h
         h.cust_code                                                                                                    cust_code               , --�ڋq�R�[�h
         h.condition_no                                                                                                 condition_no            , --�T���ԍ�
         h.target_date_end                                                                                              target_date_end         , --�Ώۊ���TO
         (SELECT SUM(deduction_amt)  FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num)  deduction_amt           , --�T��NO��_�T���z(�Ŕ�)
         (SELECT SUM(deduction_tax)  FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num)  deduction_tax           , --�T��NO��_�T���z(�����)
         (SELECT SUM(payment_amt)    FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num)  payment_amt             , --�T��NO��_�x���z(�Ŕ�)
         (SELECT SUM(payment_tax)    FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num)  payment_tax             , --�T��NO��_�x���z(�����)
         (SELECT SUM(difference_amt) FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num)  difference_amt          , --�T��NO��_�������z(�Ŕ�)
         (SELECT SUM(difference_tax) FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num)  difference_tax          , --�T��NO��_�������z(�����)
         s.creation_date                                                                                                creation_date_s         , --������͍쐬��
         s.invoice_id                                                                                                   invoice_id              , --������͓`�[ID
         s.wf_status                                                                                                    wf_status               , --������̓X�e�[�^�X
         s.invoice_num                                                                                                  invoice_num             , --������͓`�[�ԍ�
         s.requestor_person_name                                                                                        requestor_person_name   , --������͐\���Җ�
         s.approver_person_name                                                                                         approver_person_name      --������͏��F�Җ�
       FROM    xxcok.xxcok_deduction_recon_head h,
               xx03.xx03_payment_slips s
       WHERE   s.slip_type = '30000'
       AND     s.orig_invoice_num is null
       AND     s.wf_status = '80'
       AND     h.recon_slip_num = s.description
       AND     h.recon_status not in ('AD','CD','SD')
       AND    ( s.last_update_date >= ld_date 
              OR
                h.last_update_date >= ld_date 
              )
       ORDER BY DESCRIPTION;
    -- ���C���J�[�\�����R�[�h�^
    main_rec8  main_cur8%ROWTYPE;
--
--2022/06/08 1.1 add end
-- 2022/08/02 Ver1.2 ADD Start
    -- �� ���z�f�[�^�������͌J�z�f�[�^��������쐬����Ă���x���`�[
    CURSOR main_cur9
    IS
      SELECT
        ilv.recon_base_code   recon_base_code , -- �x���������_
        ilv.recon_slip_num    recon_slip_num  , -- �x���`�[�ԍ�
        ilv.application_date  application_date, -- �\����
        ilv.approval_date     approval_date   , -- ���F��
        ilv.recon_due_date    recon_due_date  , -- �x���\���
        ilv.payee_code        payee_code      , -- �x����R�[�h
        ilv.invoice_number    invoice_number  , -- �≮�������ԍ�
        ilv.applicant         applicant       , -- �\����
        ilv.approver          approver          -- ���F��
      FROM
      (
        SELECT
          xdrh.recon_base_code  recon_base_code , -- �x���������_
          xdrh.recon_slip_num   recon_slip_num  , -- �x���`�[�ԍ�
          xdrh.application_date application_date, -- �\����
          xdrh.approval_date    approval_date   , -- ���F��
          xdrh.recon_due_date   recon_due_date  , -- �x���\���
          xdrh.payee_code       payee_code      , -- �x����R�[�h
          xdrh.invoice_number   invoice_number  , -- �≮�������ԍ�
          xdrh.applicant        applicant       , -- �\����
          xdrh.approver         approver          -- ���F��
        FROM
          xxcok.xxcok_sales_deduction       xsd ,
          xxcok.xxcok_deduction_recon_head  xdrh
        WHERE
          xdrh.recon_status   =   'AD'                and
          xdrh.approval_date  >=  ld_date             and
          xsd.recon_slip_num  =   xdrh.recon_slip_num and
          xsd.status          =   'N'                 and
          xsd.source_category in  ('D','O')
        GROUP BY
          xdrh.recon_base_code    , -- �x���������_
          xdrh.recon_slip_num     , -- �x���`�[�ԍ�
          xdrh.application_date   , -- �\����
          xdrh.approval_date      , -- ���F��
          xdrh.recon_due_date     , -- �x���\���
          xdrh.payee_code         , -- �x����R�[�h
          xdrh.invoice_number     , -- �≮�������ԍ�
          xdrh.applicant          , -- �\����
          xdrh.approver           , -- ���F��
          xsd.condition_no        , -- �T���ԍ�
          xsd.tax_code            , -- �ŃR�[�h
          xsd.customer_code_to    , -- �U�֐�ڋq�R�[�h
-- 2023/05/25 Ver1.3 ADD Start
          xsd.base_code_to        , -- �U�֐拒�_�R�[�h
-- 2023/05/25 Ver1.3 ADD End
          xsd.deduction_chain_code, -- �T���p�`�F�[���R�[�h
          xsd.corp_code           , -- ��ƃR�[�h
          xsd.item_code             -- �i�ڃR�[�h
        HAVING count(*) > 1
      ) ilv
      GROUP BY
        ilv.recon_base_code , -- �x���������_
        ilv.recon_slip_num  , -- �x���`�[�ԍ�
        ilv.application_date, -- �\����
        ilv.approval_date   , -- ���F��
        ilv.recon_due_date  , -- �x���\���
        ilv.payee_code      , -- �x����R�[�h
        ilv.invoice_number  , -- �≮�������ԍ�
        ilv.applicant       , -- �\����
        ilv.approver          -- ���F��
      ORDER BY
        ilv.recon_base_code , -- �x���������_
        ilv.recon_slip_num  ; -- �x���`�[�ԍ�
    -- ���C���J�[�\�����R�[�h�^
    main_rec9  main_cur9%ROWTYPE;
--
-- 2022/08/02 Ver1.2 ADD End
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
      ld_date := xxccp_common_pkg2.get_process_date  ;
    ELSE
      ld_date := TO_DATE(iv_process_date,'YYYY/MM/DD HH24:MI:SS')  ;
    END IF;
    -- �����Ɩ����t�o��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => '�����Ɩ����t�F'|| TO_CHAR(ld_date,'YYYY/MM/DD')
    );
    -- �����Ɩ����t�̑O��������`�F�b�N�ΏۂƂ���
    ld_date := ld_date -1 ;
--
    -- ===============================
    -- ������
    -- ===============================
--
    -- �f�[�^���o��
    FOR main_rec1 IN main_cur1 LOOP
      --�����Z�b�g
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => '�T���������׏��iAP�\���j�̒������z���T���z - �x���z�ƈ�v���܂���B�܂��͒������z(�Ŋz)���T���z(�Ŋz) - �x���z(�Ŋz)�ƈ�v���܂���B'     || CHR(10) ||
                   '  �x���������_:'          || main_rec1.recon_base_code                        || CHR(10) ||  -- �x���������_       
                   '  �x���`�[�ԍ�:'          || main_rec1.recon_slip_num                         || CHR(10) ||  -- �x���`�[�ԍ�       
                   '  �����X�e�[�^�X:'        || main_rec1.recon_status                           || CHR(10) ||  -- �����X�e�[�^�X     
                   '  �\����:'                || main_rec1.applicant                              || CHR(10) ||  -- �\����             
                   '  �\����:'                || TO_CHAR(main_rec1.application_date,'YYYY/MM/DD') || CHR(10) ||  -- �\����             
                   '  ���F��:'                || main_rec1.approver                               || CHR(10) ||  -- ���F��             
                   '  ���F��:'                || TO_CHAR(main_rec1.approval_date,'YYYY/MM/DD')    || CHR(10) ||  -- ���F��             
                   '  �x����:'                || main_rec1.payee_code                             || CHR(10) ||  -- �x����             
                   '  ���������t:'            || TO_CHAR(main_rec1.invoice_date,'YYYY/MM/DD')     || CHR(10) ||  -- ���������t         
                   '  �x���\���:'            || TO_CHAR(main_rec1.recon_due_date,'YYYY/MM/DD')   || CHR(10) ||  -- �x���\���         
                   '  �A�g��:'                || main_rec1.interface_div                          || CHR(10) ||  -- �A�g��             
                   '  GL�L����:'              || TO_CHAR(main_rec1.gl_date,'YYYY/MM/DD')          || CHR(10) ||  -- GL�L����           
                   '  ����_���:'             || main_rec1.corp_code                              || CHR(10) ||  -- ����_���          
                   '  ����_�T���p�`�F�[��:'   || main_rec1.deduction_chain_code_c                 || CHR(10) ||  -- ����_�T���p�`�F�[��
                   '  ����_�ڋq:'             || main_rec1.cust_code                              || CHR(10) ||  -- ����_�ڋq          
                   '  ����_�T���ԍ�:'         || main_rec1.condition_no                           || CHR(10) ||  -- ����_�T���ԍ�      
                   '  ����_�Ώۃf�[�^���:'   || main_rec1.target_data_type                       || CHR(10) ||  -- ����_�Ώۃf�[�^���
                   '  ����_�Ώۊ���TO:'       || main_rec1.target_date_end                        || CHR(10) ||  -- ����_�Ώۊ���TO    
                   '  ����_��̐������ԍ�:'   || main_rec1.invoice_number                         || CHR(10) ||  -- ����_��̐������ԍ�
                   '  �T���p�`�F�[��:'        || main_rec1.deduction_chain_code                   || CHR(10) ||  -- �T���p�`�F�[��     
                   '  �T���z_�{�̊z:'         || main_rec1.deduction_amt                          || CHR(10) ||  -- �T���z_�{�̊z      
                   '  �x���z_�{�̊z:'         || main_rec1.payment_amt                            || CHR(10) ||  -- �x���z_�{�̊z      
                   '  �������z_�{�̊z:'       || main_rec1.difference_amt                         || CHR(10) ||  -- �������z_�{�̊z    
                   '  �T���z_�Ŋz:'           || main_rec1.deduction_tax                          || CHR(10) ||  -- �T���z_�Ŋz        
                   '  �x���z_�Ŋz:'           || main_rec1.payment_tax                            || CHR(10) ||  -- �x���z_�Ŋz        
                   '  �������z_�Ŋz:'         || main_rec1.difference_tax                         || CHR(10)     -- �������z_�Ŋz      
      );
    END LOOP;
--
    FOR main_rec2 IN main_cur2 LOOP
      --�����Z�b�g
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => '�T��No�ʏ������̒������z���T���z - �x���z�ƈ�v���܂���B�܂��͒������z(�Ŋz)���T���z(�Ŋz) - �x���z(�Ŋz)�ƈ�v���܂���B'   || CHR(10) ||
                   '  �x���������_:'          || main_rec2.recon_base_code                        || CHR(10) ||  -- �x���������_       
                   '  �x���`�[�ԍ�:'          || main_rec2.recon_slip_num                         || CHR(10) ||  -- �x���`�[�ԍ�       
                   '  �����X�e�[�^�X:'        || main_rec2.recon_status                           || CHR(10) ||  -- �����X�e�[�^�X     
                   '  �\����:'                || main_rec2.applicant                              || CHR(10) ||  -- �\����             
                   '  �\����:'                || TO_CHAR(main_rec2.application_date,'YYYY/MM/DD') || CHR(10) ||  -- �\����             
                   '  ���F��:'                || main_rec2.approver                               || CHR(10) ||  -- ���F��             
                   '  ���F��:'                || TO_CHAR(main_rec2.approval_date,'YYYY/MM/DD')    || CHR(10) ||  -- ���F��             
                   '  �x����:'                || main_rec2.payee_code                             || CHR(10) ||  -- �x����             
                   '  ���������t:'            || TO_CHAR(main_rec2.invoice_date,'YYYY/MM/DD')     || CHR(10) ||  -- ���������t         
                   '  �x���\���:'            || TO_CHAR(main_rec2.recon_due_date,'YYYY/MM/DD')   || CHR(10) ||  -- �x���\���         
                   '  �A�g��:'                || main_rec2.interface_div                          || CHR(10) ||  -- �A�g��             
                   '  GL�L����:'              || TO_CHAR(main_rec2.gl_date,'YYYY/MM/DD')          || CHR(10) ||  -- GL�L����           
                   '  ����_���:'             || main_rec2.corp_code                              || CHR(10) ||  -- ����_���          
                   '  ����_�T���p�`�F�[��:'   || main_rec2.deduction_chain_code_c                 || CHR(10) ||  -- ����_�T���p�`�F�[��
                   '  ����_�ڋq:'             || main_rec2.cust_code                              || CHR(10) ||  -- ����_�ڋq          
                   '  ����_�T���ԍ�:'         || main_rec2.condition_no_c                         || CHR(10) ||  -- ����_�T���ԍ�      
                   '  ����_�Ώۃf�[�^���:'   || main_rec2.target_data_type                       || CHR(10) ||  -- ����_�Ώۃf�[�^���
                   '  ����_�Ώۊ���TO:'       || main_rec2.target_date_end                        || CHR(10) ||  -- ����_�Ώۊ���TO    
                   '  ����_��̐������ԍ�:'   || main_rec2.invoice_number                         || CHR(10) ||  -- ����_��̐������ԍ�
                   '  �T���p�`�F�[��:'        || main_rec2.deduction_chain_code                   || CHR(10) ||  -- �T���p�`�F�[��     
                   '  �T���ԍ�:'              || main_rec2.condition_no                           || CHR(10) ||  -- �T���ԍ�           
                   '  �f�[�^���:'            || main_rec2.data_type                              || CHR(10) ||  -- �f�[�^���         
                   '  �x�����ŃR�[�h:'        || main_rec2.payment_tax_code                       || CHR(10) ||  -- �x�����ŃR�[�h     
                   '  �T���z_�{�̊z:'         || main_rec2.deduction_amt                          || CHR(10) ||  -- �T���z_�{�̊z      
                   '  �x���z_�{�̊z:'         || main_rec2.payment_amt                            || CHR(10) ||  -- �x���z_�{�̊z      
                   '  �������z_�{�̊z:'       || main_rec2.difference_amt                         || CHR(10) ||  -- �������z_�{�̊z    
                   '  �T���z_�Ŋz:'           || main_rec2.deduction_tax                          || CHR(10) ||  -- �T���z_�Ŋz        
                   '  �x���z_�Ŋz:'           || main_rec2.payment_tax                            || CHR(10) ||  -- �x���z_�Ŋz        
                   '  �������z_�Ŋz:'         || main_rec2.difference_tax                         || CHR(10)     -- �������z_�Ŋz      
      );
    END LOOP;
--
    FOR main_rec3 IN main_cur3 LOOP
      --�����Z�b�g
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => '�T���������׏��i�≮�����j�̒������z���T���z - �x���z�ƈ�v���܂���B�܂��͒������z(�Ŋz)���T���z(�Ŋz) - �x���z(�Ŋz)�ƈ�v���܂���B'   || CHR(10) ||
                   '  �x���������_:'          || main_rec3.recon_base_code                        || CHR(10) ||  -- �x���������_       
                   '  �x���`�[�ԍ�:'          || main_rec3.recon_slip_num                         || CHR(10) ||  -- �x���`�[�ԍ�       
                   '  �����X�e�[�^�X:'        || main_rec3.recon_status                           || CHR(10) ||  -- �����X�e�[�^�X     
                   '  �\����:'                || main_rec3.applicant                              || CHR(10) ||  -- �\����             
                   '  �\����:'                || TO_CHAR(main_rec3.application_date,'YYYY/MM/DD') || CHR(10) ||  -- �\����             
                   '  ���F��:'                || main_rec3.approver                               || CHR(10) ||  -- ���F��             
                   '  ���F��:'                || TO_CHAR(main_rec3.approval_date,'YYYY/MM/DD')    || CHR(10) ||  -- ���F��             
                   '  �x����:'                || main_rec3.payee_code                             || CHR(10) ||  -- �x����             
                   '  ���������t:'            || TO_CHAR(main_rec3.invoice_date,'YYYY/MM/DD')     || CHR(10) ||  -- ���������t         
                   '  �x���\���:'            || TO_CHAR(main_rec3.recon_due_date,'YYYY/MM/DD')   || CHR(10) ||  -- �x���\���         
                   '  �A�g��:'                || main_rec3.interface_div                          || CHR(10) ||  -- �A�g��             
                   '  GL�L����:'              || TO_CHAR(main_rec3.gl_date,'YYYY/MM/DD')          || CHR(10) ||  -- GL�L����           
                   '  ����_���:'             || main_rec3.corp_code                              || CHR(10) ||  -- ����_���          
                   '  ����_�T���p�`�F�[��:'   || main_rec3.deduction_chain_code_c                 || CHR(10) ||  -- ����_�T���p�`�F�[��
                   '  ����_�ڋq:'             || main_rec3.cust_code                              || CHR(10) ||  -- ����_�ڋq          
                   '  ����_�T���ԍ�:'         || main_rec3.condition_no                           || CHR(10) ||  -- ����_�T���ԍ�      
                   '  ����_�Ώۃf�[�^���:'   || main_rec3.target_data_type                       || CHR(10) ||  -- ����_�Ώۃf�[�^���
                   '  ����_�Ώۊ���TO:'       || main_rec3.target_date_end                        || CHR(10) ||  -- ����_�Ώۊ���TO    
                   '  ����_��̐������ԍ�:'   || main_rec3.invoice_number                         || CHR(10) ||  -- ����_��̐������ԍ�
                   '  �T���p�`�F�[��:'        || main_rec3.deduction_chain_code                   || CHR(10) ||  -- �T���p�`�F�[��     
                   '  �T���z_�{�̊z:'         || main_rec3.deduction_amt                          || CHR(10) ||  -- �T���z_�{�̊z      
                   '  �x���z_�{�̊z:'         || main_rec3.payment_amt                            || CHR(10) ||  -- �x���z_�{�̊z      
                   '  �������z_�{�̊z:'       || main_rec3.difference_amt                         || CHR(10) ||  -- �������z_�{�̊z    
                   '  �T���z_�Ŋz:'           || main_rec3.deduction_tax                          || CHR(10) ||  -- �T���z_�Ŋz        
                   '  �x���z_�Ŋz:'           || main_rec3.payment_tax                            || CHR(10) ||  -- �x���z_�Ŋz        
                   '  �������z_�Ŋz:'         || main_rec3.difference_tax                         || CHR(10)     -- �������z_�Ŋz      
      );
    END LOOP;
--
    FOR main_rec4 IN main_cur4 LOOP
      --�����Z�b�g
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => '���i�ʓˍ����̒������z���T���z - �x���z�ƈ�v���܂���B�܂��͒������z(�Ŋz)���T���z(�Ŋz) - �x���z(�Ŋz)�ƈ�v���܂���B'   || CHR(10) ||
                   '  �x���������_:'          || main_rec4.recon_base_code                        || CHR(10) ||  -- �x���������_       
                   '  �x���`�[�ԍ�:'          || main_rec4.recon_slip_num                         || CHR(10) ||  -- �x���`�[�ԍ�       
                   '  �����X�e�[�^�X:'        || main_rec4.recon_status                           || CHR(10) ||  -- �����X�e�[�^�X     
                   '  �\����:'                || main_rec4.applicant                              || CHR(10) ||  -- �\����             
                   '  �\����:'                || TO_CHAR(main_rec4.application_date,'YYYY/MM/DD') || CHR(10) ||  -- �\����             
                   '  ���F��:'                || main_rec4.approver                               || CHR(10) ||  -- ���F��             
                   '  ���F��:'                || TO_CHAR(main_rec4.approval_date,'YYYY/MM/DD')    || CHR(10) ||  -- ���F��             
                   '  �x����:'                || main_rec4.payee_code                             || CHR(10) ||  -- �x����             
                   '  ���������t:'            || TO_CHAR(main_rec4.invoice_date,'YYYY/MM/DD')     || CHR(10) ||  -- ���������t         
                   '  �x���\���:'            || TO_CHAR(main_rec4.recon_due_date,'YYYY/MM/DD')   || CHR(10) ||  -- �x���\���         
                   '  �A�g��:'                || main_rec4.interface_div                          || CHR(10) ||  -- �A�g��             
                   '  GL�L����:'              || TO_CHAR(main_rec4.gl_date,'YYYY/MM/DD')          || CHR(10) ||  -- GL�L����           
                   '  ����_���:'             || main_rec4.corp_code                              || CHR(10) ||  -- ����_���          
                   '  ����_�T���p�`�F�[��:'   || main_rec4.deduction_chain_code_c                 || CHR(10) ||  -- ����_�T���p�`�F�[��
                   '  ����_�ڋq:'             || main_rec4.cust_code                              || CHR(10) ||  -- ����_�ڋq          
                   '  ����_�T���ԍ�:'         || main_rec4.condition_no                           || CHR(10) ||  -- ����_�T���ԍ�      
                   '  ����_�Ώۃf�[�^���:'   || main_rec4.target_data_type                       || CHR(10) ||  -- ����_�Ώۃf�[�^���
                   '  ����_�Ώۊ���TO:'       || main_rec4.target_date_end                        || CHR(10) ||  -- ����_�Ώۊ���TO    
                   '  ����_��̐������ԍ�:'   || main_rec4.invoice_number                         || CHR(10) ||  -- ����_��̐������ԍ�
                   '  �T���p�`�F�[��:'        || main_rec4.deduction_chain_code                   || CHR(10) ||  -- �T���p�`�F�[��     
                   '  �i��:'                  || main_rec4.item_code                              || CHR(10) ||  -- �i��               
                   '  ����ŃR�[�h:'          || main_rec4.tax_code                               || CHR(10) ||  -- ����ŃR�[�h       
                   '  �T���z_�{�̊z:'         || main_rec4.deduction_amt                          || CHR(10) ||  -- �T���z_�{�̊z      
                   '  �x���z_�{�̊z:'         || main_rec4.payment_amt                            || CHR(10) ||  -- �x���z_�{�̊z      
                   '  �������z_�{�̊z:'       || main_rec4.difference_amt                         || CHR(10) ||  -- �������z_�{�̊z    
                   '  �T���z_�Ŋz:'           || main_rec4.deduction_tax                          || CHR(10) ||  -- �T���z_�Ŋz        
                   '  �x���z_�Ŋz:'           || main_rec4.payment_tax                            || CHR(10) ||  -- �x���z_�Ŋz        
                   '  �������z_�Ŋz:'         || main_rec4.difference_tax                         || CHR(10)     -- �������z_�Ŋz      
      );
    END LOOP;
--
    FOR main_rec5 IN main_cur5 LOOP
      --�����Z�b�g
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => '�T��No�ʏ������̎x���z�ƍT���������ׂ̎x���z����v���܂���B�܂��͍T��No�ʏ������̎x���Ŋz�ƍT���������ׂ̎x���Ŋz����v���܂���B'   || CHR(10) ||
                   '  �x���������_:'          || main_rec5.recon_base_code                        || CHR(10) ||  -- �x���������_       
                   '  �x���`�[�ԍ�:'          || main_rec5.recon_slip_num                         || CHR(10) ||  -- �x���`�[�ԍ�       
                   '  �����X�e�[�^�X:'        || main_rec5.recon_status                           || CHR(10) ||  -- �����X�e�[�^�X     
                   '  �\����:'                || main_rec5.applicant                              || CHR(10) ||  -- �\����             
                   '  �\����:'                || TO_CHAR(main_rec5.application_date,'YYYY/MM/DD') || CHR(10) ||  -- �\����             
                   '  ���F��:'                || main_rec5.approver                               || CHR(10) ||  -- ���F��             
                   '  ���F��:'                || TO_CHAR(main_rec5.approval_date,'YYYY/MM/DD')    || CHR(10) ||  -- ���F��             
                   '  �x����:'                || main_rec5.payee_code                             || CHR(10) ||  -- �x����             
                   '  ���������t:'            || TO_CHAR(main_rec5.invoice_date,'YYYY/MM/DD')     || CHR(10) ||  -- ���������t         
                   '  �x���\���:'            || TO_CHAR(main_rec5.recon_due_date,'YYYY/MM/DD')   || CHR(10) ||  -- �x���\���         
                   '  �A�g��:'                || main_rec5.interface_div                          || CHR(10) ||  -- �A�g��             
                   '  GL�L����:'              || TO_CHAR(main_rec5.gl_date,'YYYY/MM/DD')          || CHR(10) ||  -- GL�L����           
                   '  ����_���:'             || main_rec5.corp_code                              || CHR(10) ||  -- ����_���          
                   '  ����_�T���p�`�F�[��:'   || main_rec5.deduction_chain_code_c                 || CHR(10) ||  -- ����_�T���p�`�F�[��
                   '  ����_�ڋq:'             || main_rec5.cust_code                              || CHR(10) ||  -- ����_�ڋq          
                   '  ����_�T���ԍ�:'         || main_rec5.condition_no                           || CHR(10) ||  -- ����_�T���ԍ�      
                   '  ����_�Ώۃf�[�^���:'   || main_rec5.target_data_type                       || CHR(10) ||  -- ����_�Ώۃf�[�^���
                   '  ����_�Ώۊ���TO:'       || main_rec5.target_date_end                        || CHR(10) ||  -- ����_�Ώۊ���TO    
                   '  ����_��̐������ԍ�:'   || main_rec5.invoice_number                         || CHR(10) ||  -- ����_��̐������ԍ�
--2022/06/08 1.1 add start
                   '  �T���p�`�F�[��:'        || main_rec5.deduction_chain_code                   || CHR(10) ||  -- �T���p�`�F�[��     
--2022/06/08 1.1 add end
                   '  �T���z_�{�̊z:'         || main_rec5.deduction_amt                          || CHR(10) ||  -- �T���z_�{�̊z       
                   '  �T���z_�Ŋz:'           || main_rec5.deduction_tax                          || CHR(10) ||  -- �T���z_�Ŋz         
                   '  �x���z_�{�̊z:'         || main_rec5.payment_amt                            || CHR(10) ||  -- �x���z_�{�̊z       
                   '  �x���z_�Ŋz:'           || main_rec5.payment_tax                            || CHR(10) ||  -- �x���z_�Ŋz         
                   '  �������z_�{�̊z:'       || main_rec5.difference_amt                         || CHR(10) ||  -- �������z_�{�̊z     
                   '  �������z_�Ŋz:'         || main_rec5.difference_tax                         || CHR(10) ||  -- �������z_�Ŋz       
                   '  �x���z_�{�̊z_�T��No��:'|| main_rec5.sum_payment_amt                        || CHR(10) ||  -- �x���z_�{�̊z_�T��No��
                   '  �x���z_�Ŋz_�T��No��:'  || main_rec5.sum_payment_tax                        || CHR(10)     -- �x���z_�Ŋz_�T��No��  
      );
    END LOOP;
--
    FOR main_rec6 IN main_cur6 LOOP
      --�����Z�b�g
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => '���i�ʓˍ����̎x���z�ƍT���������ׂ̎x���z����v���܂���B�܂��͏��i�ʓˍ����̎x���Ŋz�ƍT���������ׂ̎x���Ŋz����v���܂���B'   || CHR(10) ||
                   '  �x���������_:'          || main_rec6.recon_base_code                        || CHR(10) ||  -- �x���������_       
                   '  �x���`�[�ԍ�:'          || main_rec6.recon_slip_num                         || CHR(10) ||  -- �x���`�[�ԍ�       
                   '  �����X�e�[�^�X:'        || main_rec6.recon_status                           || CHR(10) ||  -- �����X�e�[�^�X     
                   '  �\����:'                || main_rec6.applicant                              || CHR(10) ||  -- �\����             
                   '  �\����:'                || TO_CHAR(main_rec6.application_date,'YYYY/MM/DD') || CHR(10) ||  -- �\����             
                   '  ���F��:'                || main_rec6.approver                               || CHR(10) ||  -- ���F��             
                   '  ���F��:'                || TO_CHAR(main_rec6.approval_date,'YYYY/MM/DD')    || CHR(10) ||  -- ���F��             
                   '  �x����:'                || main_rec6.payee_code                             || CHR(10) ||  -- �x����             
                   '  ���������t:'            || TO_CHAR(main_rec6.invoice_date,'YYYY/MM/DD')     || CHR(10) ||  -- ���������t         
                   '  �x���\���:'            || TO_CHAR(main_rec6.recon_due_date,'YYYY/MM/DD')   || CHR(10) ||  -- �x���\���         
                   '  �A�g��:'                || main_rec6.interface_div                          || CHR(10) ||  -- �A�g��             
                   '  GL�L����:'              || TO_CHAR(main_rec6.gl_date,'YYYY/MM/DD')          || CHR(10) ||  -- GL�L����           
                   '  ����_���:'             || main_rec6.corp_code                              || CHR(10) ||  -- ����_���          
                   '  ����_�T���p�`�F�[��:'   || main_rec6.deduction_chain_code_c                 || CHR(10) ||  -- ����_�T���p�`�F�[��
                   '  ����_�ڋq:'             || main_rec6.cust_code                              || CHR(10) ||  -- ����_�ڋq          
                   '  ����_�T���ԍ�:'         || main_rec6.condition_no                           || CHR(10) ||  -- ����_�T���ԍ�      
                   '  ����_�Ώۃf�[�^���:'   || main_rec6.target_data_type                       || CHR(10) ||  -- ����_�Ώۃf�[�^���
                   '  ����_�Ώۊ���TO:'       || main_rec6.target_date_end                        || CHR(10) ||  -- ����_�Ώۊ���TO    
                   '  ����_��̐������ԍ�:'   || main_rec6.invoice_number                         || CHR(10) ||  -- ����_��̐������ԍ�
--2022/06/08 1.1 add start
                   '  �T���p�`�F�[��:'        || main_rec6.deduction_chain_code                   || CHR(10) ||  -- �T���p�`�F�[��     
--2022/06/08 1.1 add end
                   '  �T���z_�{�̊z:'         || main_rec6.deduction_amt                          || CHR(10) ||  -- �T���z_�{�̊z        
                   '  �T���z_�Ŋz:'           || main_rec6.deduction_tax                          || CHR(10) ||  -- �T���z_�Ŋz          
                   '  �x���z_�{�̊z:'         || main_rec6.payment_amt                            || CHR(10) ||  -- �x���z_�{�̊z        
                   '  �x���z_�Ŋz:'           || main_rec6.payment_tax                            || CHR(10) ||  -- �x���z_�Ŋz          
                   '  �������z_�{�̊z:'       || main_rec6.difference_amt                         || CHR(10) ||  -- �������z_�{�̊z      
                   '  �������z_�Ŋz:'         || main_rec6.difference_tax                         || CHR(10) ||  -- �������z_�Ŋz        
                   '  �x���z_�{�̊z_���i��:'  || main_rec6.sum_payment_amt                        || CHR(10) ||  -- �x���z_�{�̊z_���i�� 
                   '  �x���z_�Ŋz_���i��:'    || main_rec6.sum_payment_tax                        || CHR(10)     -- �x���z_�Ŋz_���i��   
      );
    END LOOP;
--
--2022/06/08 1.1 add start
--
    FOR main_rec7 IN main_cur7 LOOP
      --�����Z�b�g
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => '�̔��T�����̍T���z���T��No�ʏ������̍T���z + ���i�ʓˍ����̍T���z�ƈ�v���܂���B�܂��͔̔��T�����̐Ŋz���T��No�ʏ������̐Ŋz + ���i�ʓˍ����̐Ŋz�ƈ�v���܂���B'   || CHR(10) ||
                   '  �쐬��:'                      || TO_CHAR(main_rec7.creation_date,'YYYY/MM/DD HH24:MI:SS') || CHR(10) ||  -- �쐬��
                   '  �T�������w�b�_�[ID:'          || main_rec7.deduction_recon_head_id                        || CHR(10) ||  -- �T�������w�b�_�[ID
                   '  �x���`�[�ԍ�:'                || main_rec7.recon_slip_num                                 || CHR(10) ||  -- �x���`�[�ԍ�
                   '  �\����:'                      || main_rec7.applicant                                      || CHR(10) ||  -- �\����
                   '  �\���Җ�:'                    || main_rec7.applicant_name                                 || CHR(10) ||  -- �\���Җ�
                   '  ���F��:'                      || main_rec7.approver                                       || CHR(10) ||  -- ���F��
                   '  ���F�Җ�:'                    || main_rec7.approver_name                                  || CHR(10) ||  -- ���F�Җ�
                   '  �x���\���:'                  || TO_CHAR(main_rec7.recon_due_date,'YYYY/MM/DD')           || CHR(10) ||  -- �x���\���
                   '  �x���������_:'                || main_rec7.recon_base_code                                || CHR(10) ||  -- �x���������_
                   '  �x����R�[�h:'                || main_rec7.payee_code                                     || CHR(10) ||  -- �x����R�[�h
                   '  �����X�e�[�^�X�R�[�h:'        || main_rec7.recon_status_code                              || CHR(10) ||  -- �����X�e�[�^�X�R�[�h
                   '  �����X�e�[�^�X:'              || main_rec7.recon_status                                   || CHR(10) ||  -- �����X�e�[�^�X
                   '  ��ƃR�[�h:'                  || main_rec7.corp_code                                      || CHR(10) ||  -- ��ƃR�[�h
                   '  �T���p�`�F�[���R�[�h:'        || main_rec7.deduction_chain_code                           || CHR(10) ||  -- �T���p�`�F�[���R�[�h
                   '  �ڋq�R�[�h:'                  || main_rec7.cust_code                                      || CHR(10) ||  -- �ڋq�R�[�h
                   '  �T���ԍ�:'                    || main_rec7.condition_no                                   || CHR(10) ||  -- �T���ԍ�
                   '  �Ώۊ���TO:'                  || TO_CHAR(main_rec7.target_date_end,'YYYY/MM/DD')          || CHR(10) ||  -- �Ώۊ���TO
                   '  �A�g��:'                      || main_rec7.interface_div                                  || CHR(10) ||  -- �A�g��
                   '  �T��NO��_�T���z(�Ŕ�):'       || main_rec7.n_deduction_amt                                || CHR(10) ||  -- �T��NO��_�T���z(�Ŕ�)
                   '  �i�ڕ�_�T���z(�Ŕ�):'         || main_rec7.i_deduction_amt                                || CHR(10) ||  -- �i�ڕ�_�T���z(�Ŕ�)
                   '  �T���f�[�^_�T���z(�Ŕ�):'     || main_rec7.s_deduction_amount                             || CHR(10) ||  -- �T���f�[�^_�T���z(�Ŕ�)
                   '  �ُ�l(�Ŕ�):'                || main_rec7.deduction_amt_diff                             || CHR(10) ||  -- �ُ�l(�Ŕ�)
                   '  �T��NO��_�T���z(�����):'     || main_rec7.n_deduction_tax                                || CHR(10) ||  -- �T��NO��_�T���z(�����)
                   '  �i�ڕ�_�T���z(�����):'       || main_rec7.i_deduction_tax                                || CHR(10) ||  -- �i�ڕ�_�T���z(�����)
                   '  �T���f�[�^_�T���z(�����):'   || main_rec7.s_deduction_tax_amount                         || CHR(10) ||  -- �T���f�[�^_�T���z(�����)
                   '  �Ŋz�ُ�l(�����):'          || main_rec7.deduction_tax_diff                             || CHR(10)     -- �Ŋz�ُ�l(�����)
      );
    END LOOP;
--
    FOR main_rec8 IN main_cur8 LOOP
      --�����Z�b�g
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => 'AP������͓`�[�̃X�e�[�^�X�����F�ςŁA�T�������w�b�_�[���̃X�e�[�^�X���폜�ς݂̃f�[�^�����m���܂����B'   || CHR(10) ||
                   '  �쐬��:'                      || TO_CHAR(main_rec8.creation_date,'YYYY/MM/DD HH24:MI:SS')   || CHR(10) ||  -- �쐬��
                   '  �T�������w�b�_�[ID:'          || main_rec8.deduction_recon_head_id                          || CHR(10) ||  -- �T�������w�b�_�[ID
                   '  �x���`�[�ԍ�:'                || main_rec8.recon_slip_num                                   || CHR(10) ||  -- �x���`�[�ԍ�
                   '  �\����:'                      || main_rec8.applicant                                        || CHR(10) ||  -- �\����
                   '  �\���Җ�:'                    || main_rec8.applicant_name                                   || CHR(10) ||  -- �\���Җ�
                   '  ���F��:'                      || main_rec8.approver                                         || CHR(10) ||  -- ���F��
                   '  ���F�Җ�:'                    || main_rec8.approver_name                                    || CHR(10) ||  -- ���F�Җ�
                   '  �x���\���:'                  || TO_CHAR(main_rec8.recon_due_date,'YYYY/MM/DD')             || CHR(10) ||  -- �x���\���
                   '  �x���������_:'                || main_rec8.recon_base_code                                  || CHR(10) ||  -- �x���������_
                   '  �x����R�[�h:'                || main_rec8.payee_code                                       || CHR(10) ||  -- �x����R�[�h
                   '  �����X�e�[�^�X�R�[�h:'        || main_rec8.recon_status_code                                || CHR(10) ||  -- �����X�e�[�^�X�R�[�h
                   '  �����X�e�[�^�X:'              || main_rec8.recon_status                                     || CHR(10) ||  -- �����X�e�[�^�X
                   '  ��ƃR�[�h:'                  || main_rec8.corp_code                                        || CHR(10) ||  -- ��ƃR�[�h
                   '  �T���p�`�F�[���R�[�h:'        || main_rec8.deduction_chain_code                             || CHR(10) ||  -- �T���p�`�F�[���R�[�h
                   '  �ڋq�R�[�h:'                  || main_rec8.cust_code                                        || CHR(10) ||  -- �ڋq�R�[�h
                   '  �T���ԍ�:'                    || main_rec8.condition_no                                     || CHR(10) ||  -- �T���ԍ�
                   '  �Ώۊ���TO:'                  || TO_CHAR(main_rec8.target_date_end,'YYYY/MM/DD')            || CHR(10) ||  -- �Ώۊ���TO
                   '  �T��NO��_�T���z(�Ŕ�):'       || main_rec8.deduction_amt                                    || CHR(10) ||  -- �T��NO��_�T���z(�Ŕ�)
                   '  �T��NO��_�T���z(�����):'     || main_rec8.deduction_tax                                    || CHR(10) ||  -- �T��NO��_�T���z(�����)
                   '  �T��NO��_�x���z(�Ŕ�):'       || main_rec8.payment_amt                                      || CHR(10) ||  -- �T��NO��_�x���z(�Ŕ�)
                   '  �T��NO��_�x���z(�����):'     || main_rec8.payment_tax                                      || CHR(10) ||  -- �T��NO��_�x���z(�����)
                   '  �T��NO��_�������z(�Ŕ�):'     || main_rec8.difference_amt                                   || CHR(10) ||  -- �T��NO��_�������z(�Ŕ�)
                   '  �T��NO��_�������z(�����):'   || main_rec8.difference_tax                                   || CHR(10) ||  -- �T��NO��_�������z(�����)
                   '  ������͍쐬��:'              || TO_CHAR(main_rec8.creation_date_s,'YYYY/MM/DD HH24:MI:SS') || CHR(10) ||  -- ������͍쐬��
                   '  ������͓`�[ID:'              || main_rec8.invoice_id                                       || CHR(10) ||  -- ������͓`�[ID
                   '  ������̓X�e�[�^�X:'          || main_rec8.wf_status                                        || CHR(10) ||  -- ������̓X�e�[�^�X
                   '  ������͓`�[�ԍ�:'            || main_rec8.invoice_num                                      || CHR(10) ||  -- ������͓`�[�ԍ�
                   '  ������͐\���Җ�:'            || main_rec8.requestor_person_name                            || CHR(10) ||  -- ������͐\���Җ�
                   '  ������͏��F�Җ�:'            || main_rec8.approver_person_name                             || CHR(10)     -- ������͏��F�Җ�
      );
    END LOOP;
--2022/06/08 1.1 add end
-- 2022/08/02 Ver1.2 ADD Start
--
    FOR main_rec9 IN main_cur9 LOOP
      --�����Z�b�g
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => '���z�f�[�^�������͌J�z�f�[�^��������쐬����Ă���x���`�[�����m���܂����B'   || CHR(10) ||
                   '  �x���������_:'                || main_rec9.recon_base_code                        || CHR(10) ||  -- �x���������_
                   '  �x���`�[�ԍ�:'                || main_rec9.recon_slip_num                         || CHR(10) ||  -- �x���`�[�ԍ�
                   '  �\����:'                      || TO_CHAR(main_rec9.application_date,'YYYY/MM/DD') || CHR(10) ||  -- �\����
                   '  ���F��:'                      || TO_CHAR(main_rec9.approval_date   ,'YYYY/MM/DD') || CHR(10) ||  -- ���F��
                   '  �x���\���:'                  || TO_CHAR(main_rec9.recon_due_date  ,'YYYY/MM/DD') || CHR(10) ||  -- �x���\���
                   '  �x����R�[�h:'                || main_rec9.payee_code                             || CHR(10) ||  -- �x����R�[�h
                   '  �≮�������ԍ�:'              || main_rec9.invoice_number                         || CHR(10) ||  -- �≮�������ԍ�
                   '  �\����:'                      || main_rec9.applicant                              || CHR(10) ||  -- �\����
                   '  ���F��:'                      || main_rec9.approver                               || CHR(10)     -- ���F��
      );
    END LOOP;
--
-- 2022/08/02 Ver1.2 ADD End
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
END XXCCP003A05C;
/
