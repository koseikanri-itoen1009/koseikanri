CREATE OR REPLACE PACKAGE BODY XXCFR003A09C AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFR003A09C
 * Description     : �ėp���i�i�P�i���j�����f�[�^�쐬
 * MD.050          : MD050_CFR_003_A09_�ėp���i�i�P�i���j�����f�[�^�쐬
 * MD.070          : MD050_CFR_003_A09_�ėp���i�i�P�i���j�����f�[�^�쐬
 * Version         : 1.0
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  init            P         ��������
 *  get_invoice     P         �������擾����
 *  put             P         �t�@�C���o�͏���
 *  end_proc        P         �I������
 *  submain         P         �ėp���i�i�P�i���j�����f�[�^�쐬�������s��
 *  main            P         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2008-12-10    1.0   SCS ���� �^�I ����쐬
 ************************************************************************/

--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  cv_status_normal   CONSTANT VARCHAR2(1) := '0';  -- ����I��
  cv_status_warn     CONSTANT VARCHAR2(1) := '1';   --�x��
  cv_status_error    CONSTANT VARCHAR2(1) := '2';   --�G���[
  cv_msg_part        CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont        CONSTANT VARCHAR2(3) := '.';
  
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A09C';  -- �p�b�P�[�W��
  
--
--##############################  �Œ蕔 END   ####################################
--
  
  --===============================================================
  -- �O���[�o���萔
  --===============================================================
  cv_xxcfr_app_name  CONSTANT VARCHAR2(10) := 'XXCFR';  -- �A�h�I����v AR �̃A�v���P�[�V�����Z�k��
  cv_xxccp_app_name  CONSTANT VARCHAR2(10) := 'XXCCP';  -- �A�h�I���F���ʁEIF�̈�̃A�v���P�[�V�����Z�k��
  
  -- ���b�Z�[�W�ԍ�
  cv_msg_cfr_00010  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00010';
  cv_msg_cfr_00015  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00015';
  cv_msg_cfr_00016  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00016';
  cv_msg_cfr_00024  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00024';
  cv_msg_cfr_00056  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00056';
  
  cv_msg_ccp_90000  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90000';
  cv_msg_ccp_90001  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90001';
  cv_msg_ccp_90002  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90002';
  cv_msg_ccp_90004  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90004';
  cv_msg_ccp_90005  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90005';
  cv_msg_ccp_90006  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90006';
  
  -- ���b�Z�[�W�g�[�N��
  cv_tkn_get_data   CONSTANT VARCHAR2(30) := 'DATA';                 -- �擾�Ώۃf�[�^
  cv_tkn_count      CONSTANT VARCHAR2(30) := 'COUNT';                -- ��������
  cv_tkn_tab_name   CONSTANT VARCHAR2(30) := 'TABLE';                -- �e�[�u����
  cv_func_name      CONSTANT VARCHAR2(30) := 'FUNC_NAME';            -- ���ʊ֐���
  
  -- �v���t�@�C���I�v�V����
  cv_prof_name_set_of_bks_id  CONSTANT fnd_profile_options_tl.profile_option_name%TYPE := 'GL_SET_OF_BKS_ID';
  cv_prof_name_org_id         CONSTANT fnd_profile_options_tl.profile_option_name%TYPE := 'ORG_ID';
  
  -- �Q�ƃ^�C�v
  cv_lookup_type_out       CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_003A06_BILL_DATA_SET';  -- �ėp�����o�͗p�Q�ƃ^�C�v��
  
  -- �������S�Џo�͌�������֐�IN�p���[���[�^�l
  cv_invoice_type  CONSTANT VARCHAR2(1) := 'G';  -- �������^�C�v(G:�ėp������)
  
  -- �������S�Џo�͌�������֐��߂�l
  cv_yes  CONSTANT VARCHAR2(1) := 'Y';  -- �S�Џo�͌�������
  cv_no   CONSTANT VARCHAR2(1) := 'N';  -- �S�Џo�͌����Ȃ�
  
  -- �������S�Џo�͌����ݒ�l
  cv_enable_all   CONSTANT VARCHAR2(1) := '1';  -- �S�Џo�͌�������
  cv_disable_all  CONSTANT VARCHAR2(1) := '0';  -- �S�Џo�͌����Ȃ�
  
  --===============================================================
  -- �O���[�o���ϐ�
  --===============================================================
  gn_gl_set_of_bks_id       gl_sets_of_books.set_of_books_id%TYPE;     -- �v���t�@�C����v����ID
  gn_org_id                 xxcfr_bill_customers_v.org_id%TYPE;        -- �v���t�@�C���g�DID
  gv_user_dept_code         per_all_people_f.attribute28%TYPE;         -- ���O�C�����[�U��������R�[�h
  gv_enable_all             VARCHAR2(1);                               -- �S�ЎQ�ƌ���
  gn_rec_count              PLS_INTEGER := 0;                          -- ���������擾����
  
  --===============================================================
  -- �O���[�o����O
  --===============================================================
  global_process_expt       EXCEPTION; -- �֐���O
  global_api_expt           EXCEPTION; -- ���ʊ֐���O
  global_api_others_expt    EXCEPTION; -- ���ʊ֐�OTHERS��O
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);  -- ���ʊ֐���O(ORA-20000)��global_api_others_expt���}�b�s���O
  
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������
   ***********************************************************************************/
  PROCEDURE init(
    iv_target_date   IN  VARCHAR2,    -- ����
    iv_ar_code1      IN  VARCHAR2,    -- ���|�R�[�h�P(������)
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_log             CONSTANT VARCHAR2(10)  := 'LOG';          -- �p�����[�^�o�͊֐� ���O�o�͎���iv_which�l
    cv_output          CONSTANT VARCHAR2(10)  := 'OUTPUT';       -- �p�����[�^�o�͊֐� ���|�[�g�o�͎���iv_which�l
    cv_person_dff_name CONSTANT VARCHAR2(10)  := 'PER_PEOPLE';   -- �]�ƈ��}�X�^DFF��
    cv_peson_dff_att28 CONSTANT VARCHAR2(11)  := 'ATTRIBUTE28';  -- �]�ƈ��}�X�^DFF28(��������)�J������
    
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(5000); -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    lv_token_value fnd_descr_flex_col_usage_vl.end_user_column_name%TYPE; --��������擾�G���[���̃��b�Z�[�W�g�[�N���l
    
    -- ===============================
    -- ���[�J����O
    -- ===============================
    get_user_dept_expt EXCEPTION;  -- ���[�U��������擾��O
    
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    
    -- �R���J�����g�p�����[�^���O�o��
    xxcfr_common_pkg.put_log_param(iv_which => cv_log,
                                   iv_conc_param1 => iv_target_date,
                                   iv_conc_param2 => iv_ar_code1,
                                   ov_errbuf => lv_errbuf,
                                   ov_retcode => lv_retcode,
                                   ov_errmsg => lv_errmsg
                                  );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
    
    -- �v���t�@�C����v����擾
    gn_gl_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE(cv_prof_name_set_of_bks_id));
    
    -- �v���t�@�C���c�ƒP�ʎ擾
    gn_org_id := TO_NUMBER(FND_PROFILE.VALUE(cv_prof_name_org_id));
    
    -- ��������R�[�h�擾
    gv_user_dept_code := xxcfr_common_pkg.get_user_dept(in_user_id => FND_GLOBAL.USER_ID,
                                                        id_get_date => SYSDATE
                                                       );
    IF (gv_user_dept_code IS NULL) THEN
      RAISE get_user_dept_expt;
    END IF;
    
  EXCEPTION
    -- *** ���ʊ֐��G���[������ ***
    WHEN global_api_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** �������傪�擾�ł��Ȃ��ꍇ ***
    WHEN get_user_dept_expt THEN
      BEGIN
        SELECT ffcu.end_user_column_name end_user_column_name --���[�U�Z�O�����g��
        INTO lv_token_value
        FROM fnd_descr_flex_col_usage_vl ffcu                 --DFF�Z�O�����g�g�p���@�r���[
        WHERE ffcu.descriptive_flexfield_name = cv_person_dff_name
          AND ffcu.application_column_name = cv_peson_dff_att28;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => cv_msg_cfr_00015,
                                            iv_token_name1 => cv_tkn_get_data,
                                            iv_token_value1 => lv_token_value);
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END init;
  
  /**********************************************************************************
   * Procedure Name   : get_invoice
   * Description      : �������擾����
   ***********************************************************************************/
  PROCEDURE get_invoice(
    iv_target_date   IN  DATE,        -- ����
    iv_ar_code1      IN  VARCHAR2,    -- ���|�R�[�h�P(������)
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_invoice';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
--
    --===============================================================
    -- ���[�J���萔
    --===============================================================
    -- VD�ڋq�敪�l
    cv_is_vd     CONSTANT VARCHAR2(1) := '1';  -- VD�ڋq
    cv_is_not_vd CONSTANT VARCHAR2(1) := '0';  -- VD�ڋq�ȊO
    
    -- �������o�͌`��
    cv_inv_prt_type CONSTANT VARCHAR2(1) := '2';  -- �ėp������
    
    -- �ꊇ���������s�t���O
    cv_cons_inv_flag CONSTANT VARCHAR2(1) := 'Y';  -- �L��
    
    -- �\�[�g�L�[����NULL���̒l
    cv_sort_null_value CONSTANT VARCHAR2(1) := '0';
    
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(5000); -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--
    
    --===============================================================
    -- ���[�J���ϐ�
    --===============================================================
    
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- CSV�o�̓��[�N�e�[�u���֑}��
    INSERT INTO xxcfr_csv_outs_temp(
      request_id,
      seq,
      col1,
      col2,
      col3,
      col4,
      col5,
      col6,
      col7,
      col8,
      col9,
      col10,
      col11,
      col12,
      col13,
      col14,
      col15,
      col16,
      col17,
      col18,
      col19,
      col20,
      col21,
      col22,
      col23,
      col24,
      col25,
      col26,
      col27,
      col28,
      col29,
      col30,
      col31,
      col32,
      col33,
      col34,
      col35,
      col36,
      col37,
      col38,
      col39,
      col40,
      col41,
      col42,
      col43,
      col44,
      col45,
      col46,
      col47,
      col48,
      col49,
      col50,
      col51,
      col52,
      col53,
      col54,
      col55,
      col56,
      col57,
      col58,
      col59,
      col60)
    (SELECT conc_request_id,
            ROWNUM,
            itoen_name,
            inv_creation_date,
            object_month,
            object_date_from,
            object_date_to,
            vender_code,
            bill_location_code,
            bill_location_name,
            agent_tel_num,
            credit_cust_code,
            credit_cust_name,
            receipt_cust_code,
            receipt_cust_name,
            payment_cust_code,
            payment_cust_name,
            bill_cust_code,
            bill_cust_name,
            credit_receiv_code2,
            credit_receiv_name2,
            credit_receiv_code3,
            credit_receiv_name3,
            sold_location_code,
            sold_location_name,
            ship_cust_code,
            ship_cust_name,
            bill_shop_code,
            bill_shop_name,
            ship_shop_code,
            ship_shop_name,
            vd_num,
            delivery_date,
            slip_num,
            order_num,
            column_num,
            item_code,
            jan_code,
            item_name,
            vessel,
            quantity,
            unit_price,
            ship_amount,
            sold_amount,
            sold_amount_plus,
            sold_amount_minus,
            sold_amount_total,
            inv_amount_includ_tax,
            tax_amount_sum,
            bm_unit_price1,
            bm_rate1,
            bm_price1,
            bm_unit_price2,
            bm_rate2,
            bm_price2,
            bm_unit_price3,
            bm_rate3,
            bm_price3,
            vd_amount_claimed,
            electric_charges,
            slip_type,
            classify_type
     FROM (SELECT FND_GLOBAL.CONC_REQUEST_ID                       conc_request_id,          -- �v��ID
                  ''                                               sort_num,                 -- �o�͏�
                  xih.itoen_name                                   itoen_name,               -- ����於
                  TO_CHAR(xih.inv_creation_date,'YYYY/MM/DD')      inv_creation_date,        -- �쐬��
                  xih.object_month                                 object_month,             -- �Ώ۔N��
                  TO_CHAR(xih.object_date_from,'YYYY/MM/DD')       object_date_from,         -- �Ώۊ���(��)
                  TO_CHAR(xih.object_date_to,'YYYY/MM/DD')         object_date_to,           -- �Ώۊ���(��)
                  xih.vender_code                                  vender_code,              -- �����R�[�h
                  xih.bill_location_code                           bill_location_code,       -- �����S�����_�R�[�h
                  xih.bill_location_name                           bill_location_name,       -- �����S�����_��
                  xih.agent_tel_num                                agent_tel_num,            -- �����S�����_�d�b�ԍ�
                  xih.credit_cust_code                             credit_cust_code,         -- �^�M��ڋq�R�[�h
                  xih.credit_cust_name                             credit_cust_name,         -- �^�M��ڋq��
                  xih.receipt_cust_code                            receipt_cust_code,        -- ������ڋq�R�[�h
                  xih.receipt_cust_name                            receipt_cust_name,        -- ������ڋq��
                  xih.payment_cust_code                            payment_cust_code,        -- ���|�R�[�h�P�i�������j
                  xih.payment_cust_name                            payment_cust_name,        -- ���|�R�[�h�P�i�������j����
                  xih.bill_cust_code                               bill_cust_code,           -- ������ڋq�R�[�h
                  xih.bill_cust_name                               bill_cust_name,           -- ������ڋq��
                  xih.credit_receiv_code2                          credit_receiv_code2,      -- ���|�R�[�h�Q�i���Ə��j
                  xih.credit_receiv_name2                          credit_receiv_name2,      -- ���|�R�[�h�Q�i���Ə��j����
                  xih.credit_receiv_code3                          credit_receiv_code3,      -- ���|�R�[�h�R�i���̑��j
                  xih.credit_receiv_name3                          credit_receiv_name3,      -- ���|�R�[�h�R�i���̑��j����
                  NULL                                             sold_location_code,       -- ���_�R�[�h
                  NULL                                             sold_location_name,       -- ���_��
                  NULL                                             ship_cust_code,           -- �ڋq�R�[�h
                  NULL                                             ship_cust_name,           -- �ڋq��
                  NULL                                             bill_shop_code,           -- ������ڋq�XNO
                  NULL                                             bill_shop_name,           -- ������ڋq�X��
                  NULL                                             ship_shop_code,           -- �[�i��ڋq�XNO
                  NULL                                             ship_shop_name,           -- �[�i��ڋq�X��
                  NULL                                             vd_num,                   -- �����̔��@�ԍ�
                  NULL                                             delivery_date,            -- �[�i��
                  NULL                                             slip_num,                 -- �`�[NO
                  NULL                                             order_num,                -- �I�[�_�[NO
                  NULL                                             column_num,               -- �R����
                  xil.item_code                                    item_code,                -- ���i�R�[�h
                  xil.jan_code                                     jan_code,                 -- JAN�R�[�h
                  xil.item_name                                    item_name,                -- ���i��
                  DECODE(xil.vd_cust_type,
                         cv_is_vd,
                         xil.vessel_type_name,
                         NULL
                        )                                          vessel,                   -- �e��
                  SUM(xil.quantity)                                quantity,                 -- ����
                  xil.unit_price                                   unit_price,               -- ���P��
                  DECODE(xil.vd_cust_type,
                         cv_is_vd,
                         xil.unit_price,
                         NULL
                        )                                          ship_amount,              -- ����
                  SUM(xil.sold_amount)                             sold_amount,              -- ���z
                  NULL                                             sold_amount_plus,         -- ���z�i���j
                  NULL                                             sold_amount_minus,        -- ���z�i�ԁj
                  NULL                                             sold_amount_total,        -- ���z�i�v�j
                  AVG(xih.inv_amount_includ_tax)                   inv_amount_includ_tax,    -- �ō��������z
                  AVG(xih.tax_amount_sum)                          tax_amount_sum,           -- ��������ŋ��z
                  NULL                                             bm_unit_price1,           -- BM1�P��
                  NULL                                             bm_rate1,                 -- BM1��
                  NULL                                             bm_price1,                -- BM1���z
                  NULL                                             bm_unit_price2,           -- BM2�P��
                  NULL                                             bm_rate2,                 -- BM2��
                  NULL                                             bm_price2,                -- BM2���z
                  NULL                                             bm_unit_price3,           -- BM3�P��
                  NULL                                             bm_rate3,                 -- BM3��
                  NULL                                             bm_price3,                -- BM3���z
                  NULL                                             vd_amount_claimed,        -- VD�����z
                  NULL                                             electric_charges,         -- �d�C��
                  NULL                                             slip_type,                -- �`�[�敪
                  NULL                                             classify_type             -- ���ދ敪
           FROM xxcfr_invoice_headers xih,
                xxcfr_invoice_lines   xil
           WHERE xih.invoice_id = xil.invoice_id
             AND EXISTS (SELECT 'X'
                         FROM xxcfr_bill_customers_v xbcv
                         WHERE xih.bill_cust_code = xbcv.bill_customer_code
                           AND ((cv_enable_all = gv_enable_all AND
                                 xbcv.bill_base_code = xbcv.bill_base_code)
                                OR
                                (cv_disable_all = gv_enable_all AND
                                 xbcv.bill_base_code = gv_user_dept_code))
                           AND xbcv.receiv_code1 = iv_ar_code1
                           AND xbcv.inv_prt_type = cv_inv_prt_type
                           AND xbcv.cons_inv_flag = cv_cons_inv_flag
                           AND xbcv.org_id = gn_org_id
                        )
             AND xih.cutoff_date = iv_target_date
             AND xih.set_of_books_id = gn_gl_set_of_bks_id
             AND xih.org_id = gn_org_id
           GROUP BY xih.itoen_name,
                    TO_CHAR(xih.inv_creation_date,'YYYY/MM/DD'),
                    xih.object_month,
                    TO_CHAR(xih.object_date_from,'YYYY/MM/DD'),
                    TO_CHAR(xih.object_date_to,'YYYY/MM/DD'),
                    xih.vender_code,
                    xih.bill_location_code,
                    xih.bill_location_name,
                    xih.agent_tel_num,
                    xih.credit_cust_code,
                    xih.credit_cust_name,
                    xih.receipt_cust_code,
                    xih.receipt_cust_name,
                    xih.payment_cust_code,
                    xih.payment_cust_name,
                    xih.bill_cust_code,
                    xih.bill_cust_name,
                    xih.credit_receiv_code2,
                    xih.credit_receiv_name2,
                    xih.credit_receiv_code3,
                    xih.credit_receiv_name3,
                    xil.item_code,
                    xil.jan_code,
                    xil.item_name,
                    DECODE(xil.vd_cust_type,
                           cv_is_vd,
                           xil.vessel_type_name,
                           NULL
                          ),
                    xil.unit_price,
                    DECODE(xil.vd_cust_type,
                           cv_is_vd,
                           xil.unit_price,
                           NULL
                          ),
                    xil.policy_group
           ORDER BY xih.bill_cust_code,                          -- ������ڋq�R�[�h
                    xil.policy_group,                            -- ����Q�R�[�h
                    xil.item_code                                -- ���i�R�[�h
          )
    );
        -- ���������i�[
        gn_rec_count := SQL%ROWCOUNT;
    
  EXCEPTION
    WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => cv_msg_cfr_00016,
                                            iv_token_name1 => cv_tkn_tab_name,
                                            iv_token_value1 => xxcfr_common_pkg.get_table_comment('XXCFR_CSV_OUTS_TEMP')
                                           );
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
  END get_invoice;
  
  /**********************************************************************************
   * Procedure Name   : put
   * Description      : �t�@�C���o�͏���
   ***********************************************************************************/
  PROCEDURE put(
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
    --===============================================================
    -- ���[�J���萔
    --===============================================================
    -- �Q�ƃ^�C�v
    cv_lookup_type_func_name CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_ERR_MSG_TOKEN';        -- �G���[���b�Z�[�W�o�͗p�Q�ƃ^�C�v��
    
    -- �Q�ƃR�[�h
    cv_lookup_code_func_name CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFR000A00006';                -- �G���[���b�Z�[�W�o�͗p�Q�ƃ^�C�v�R�[�h
    
    --===============================================================
    -- ���[�J���ϐ�
    --===============================================================
    lv_func_name fnd_lookup_values.description%TYPE;  -- �ėp�����o�͏������ʊ֐���
    
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(5000); -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--
    
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- OUT�t�@�C���o�͏������s
    xxcfr_common_pkg.csv_out(in_request_id => FND_GLOBAL.CONC_REQUEST_ID,
                             iv_lookup_type => cv_lookup_type_out,
                             in_rec_cnt => gn_rec_count,
                             ov_retcode => lv_retcode,
                             ov_errbuf => lv_errbuf,
                             ov_errmsg => lv_errmsg
                            );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
    
  EXCEPTION
    -- *** ���ʊ֐��G���[������ ***
    WHEN global_api_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      BEGIN
        SELECT flvv.description description
        INTO lv_func_name
        FROM fnd_lookup_values_vl flvv
        WHERE flvv.lookup_type = cv_lookup_type_func_name
          AND flvv.lookup_code = cv_lookup_code_func_name
          AND flvv.enabled_flag = cv_yes
          AND SYSDATE BETWEEN flvv.start_date_active AND flvv.end_date_active;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => cv_msg_cfr_00010,
                                            iv_token_name1 => cv_func_name,
                                            iv_token_value1 => lv_func_name);
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END put;
  
  /**********************************************************************************
   * Procedure Name   : end_proc
   * Description      : �I�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE end_proc(
    iv_retcode          IN  VARCHAR2,  -- �����X�e�[�^�X
    ov_errbuf           OUT VARCHAR2,
    ov_retcode          OUT VARCHAR2,
    ov_errmsg           OUT VARCHAR2
  )
  IS
    
--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'end_proc';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
--
    
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(5000); -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--
    
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    FND_FILE.PUT_LINE(FND_FILE.LOG,'');
    
    -- �Ώۃf�[�^0���x�����b�Z�[�W�o��
    IF (iv_retcode = cv_status_warn) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                                 iv_name => cv_msg_cfr_00024
                                                )
                       );
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
    END IF;
    
    -- �����o��
    -- ����܂��͌x���I���̏ꍇ
    IF ((iv_retcode = cv_status_normal) OR (iv_retcode = cv_status_warn)) THEN
      -- �Ώی����o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90000,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => gn_rec_count
                                                )
                       );
      
      -- ���������o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90001,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => gn_rec_count
                                                )
                       );
      
      -- �G���[�����o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90002,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => 0
                                                )
                       );
    -- �G���[�I���̏ꍇ
    ELSIF (iv_retcode = cv_status_error) THEN
      -- �Ώی����o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90000,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => 0
                                                )
                       );
      
      -- ���������o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90001,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => 0
                                                )
                       );
      
      -- �G���[�����o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90002,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => 1
                                                )
                       );
      -- �G���[�����݂��Ȃ��ꍇ
    END IF;
    
    -- �I�����b�Z�[�W�o��
    -- �G���[�����݂���ꍇ
    IF (iv_retcode = cv_status_error) THEN
      -- �G���[�I�����b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90006
                                                )
                       );
    -- �Ώۃf�[�^0���̏ꍇ(�x���I��)
    ELSIF (iv_retcode = cv_status_warn) THEN
      -- �x���I�����b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90005
                                                )
                       );
    -- ����I���̏ꍇ
    ELSE
      -- ����I�����b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90004
                                                )
                       );
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END end_proc;
  
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : �ėp���i�i�P�i���j�����f�[�^�쐬�������s��
   ***********************************************************************************/
  PROCEDURE submain(
    iv_target_date   IN  VARCHAR2,    -- ����
    iv_ar_code1      IN  VARCHAR2,    -- ���|�R�[�h�P(������)
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(5000); -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--
 
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    
    --===============================================================
    -- A-1�D��������
    --===============================================================
    init(iv_target_date,
         iv_ar_code1,
         lv_errbuf,
         lv_retcode,
         lv_errmsg
        );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    
    --===============================================================
    -- A-2�D�o�̓Z�L�����e�B����
    --===============================================================
    gv_enable_all := xxcfr_common_pkg.chk_invoice_all_dept(iv_user_dept_code => gv_user_dept_code,
                                                           iv_invoice_type => cv_invoice_type
                                                          );
    IF (gv_enable_all = cv_yes) THEN
      gv_enable_all := cv_enable_all;
    ELSE
      gv_enable_all := cv_disable_all;
    END IF;
    
    --===============================================================
    -- A-3�D�������擾����
    --===============================================================
    get_invoice(xxcfr_common_pkg.get_date_param_trans(iv_target_date),
                iv_ar_code1,
                lv_errbuf,
                lv_retcode,
                lv_errmsg
               );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    
    --===============================================================
    -- A-4�D�t�@�C���o�͏���
    --===============================================================
    put(lv_errbuf,
        lv_retcode,
        lv_errmsg
       );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    
    -- ��������0�̏ꍇ�x���I��
    IF (gn_rec_count = 0) THEN
      ov_retcode := cv_status_warn;
    END IF;
    
  EXCEPTION
    -- *** �T�u�v���O�����G���[������ ***
    WHEN global_process_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END submain;
  
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE main(
    errbuf           OUT VARCHAR2,
    retcode          OUT VARCHAR2,
    iv_target_date   IN  VARCHAR2,    -- ����
    iv_ar_code1      IN  VARCHAR2     -- ���|�R�[�h�P(������)
  ) IS
    
--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_put_log_which CONSTANT VARCHAR2(10) := 'LOG';  -- ���O�w�b�_�o�͊֐�iv_which�p�����[�^
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(5000); -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--
    
  BEGIN
    
    xxccp_common_pkg.put_log_header(iv_which => cv_put_log_which,
                                    ov_retcode => lv_retcode,
                                    ov_errbuf => lv_errbuf,
                                    ov_errmsg => lv_errmsg
                                   );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
    
    submain(iv_target_date,
            iv_ar_code1,
            lv_errbuf,
            lv_retcode,
            lv_errmsg
           );
    
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfr_app_name
                     ,iv_name         => cv_msg_cfr_00056
                   )
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000) --�G���[���b�Z�[�W
      );
    END IF;
    
    -- �X�e�[�^�X���Z�b�g
    retcode := lv_retcode;
    
    --===============================================================
    -- A-5�D�I������
    --===============================================================
    end_proc(retcode,
             lv_errbuf,
             lv_retcode,
             lv_errmsg
            );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    
   -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
        ROLLBACK;
    END IF;
    
  EXCEPTION
    -- *** ���ʊ֐��G���[������ ***
    WHEN global_api_expt THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
      retcode := cv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
    -- *** �T�u�v���O�����G���[������ ***
    WHEN global_process_expt THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
      retcode := cv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    WHEN OTHERS THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
  
END  XXCFR003A09C;
/
