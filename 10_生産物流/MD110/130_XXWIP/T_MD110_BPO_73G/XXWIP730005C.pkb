CREATE OR REPLACE PACKAGE BODY xxwip730005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWIP730005C(body)
 * Description      : �����^���`�F�b�N���X�g
 * MD.050/070       : �^���v�Z�i�g�����U�N�V�����j  (T_MD050_BPO_734)
 *                    �����^���`�F�b�N���X�g        (T_MD070_BPO_73G)
 * Version          : 1.14
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  prc_chk_param               PROCEDURE : �p�����[�^�`�F�b�N
 *  prc_create_xml_data_user    PROCEDURE : �^�O�o�� - ���[�U�[���
 *  prc_create_sql              PROCEDURE : �f�[�^�擾�r�p�k����
 *  prc_create_xml_data         PROCEDURE : �w�l�k�f�[�^�ҏW
 *  convert_into_xml            FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  submain                     PROCEDURE : ���C�������v���V�[�W��
 *  main                        PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/30    1.0   Masayuki Ikeda   �V�K�쐬
 *  2008/05/23    1.1   Masayuki Ikeda   �����e�X�g��Q�Ή�
 *  2008/07/02    1.2   Satoshi Yunba    �֑������u'�v�u"�v�u<�v�u>�v�u&�v�Ή�
 *  2008/07/15    1.3   Masayuki Nomura  ST��Q�Ή�#444
 *  2008/07/15    1.4   Masayuki Nomura  ST��Q�Ή�#444�i�L���Ή��j
 *  2008/07/17    1.5   Satoshi Takemoto ST��Q�Ή�#456
 *  2008/07/24    1.6   Satoshi Takemoto ST��Q�Ή�#477
 *  2008/07/25    1.7   Masayuki Nomura  ST��Q�Ή�#456
 *  2008/07/28    1.8   Masayuki Nomura  �ύX�v�������e�X�g��Q�Ή�
 *  2008/08/19    1.9   Takao Ohashi     T_TE080_BPO_730 �w�E10�Ή�
 *  2008/10/15    1.10  Yasuhisa Yamamoto ������Q#300,331
 *  2008/10/24    1.11  Masayuki Nomura  ����#439�Ή�
 *  2008/12/15    1.12  �쑺 ���K        �{��#40�Ή�
 *  2009/01/29    1.13  �쑺 ���K        �{��#431�Ή�
 *  2009/07/01    1.14  �쑺 ���K        �{��#1551�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
  -- ===============================================================================================
  -- ���[�U�[�錾��
  -- ===============================================================================================
  -- ==================================================
  -- �O���[�o���萔
  -- ==================================================
  gc_pkg_name             CONSTANT VARCHAR2(20) := 'XXWIP730005C' ;      -- �p�b�P�[�W��
  gc_report_id            CONSTANT VARCHAR2(20) := 'XXWIP730005T' ;      -- ���[ID
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;            -- �A�v���P�[�V����
  gc_application_wip      CONSTANT VARCHAR2(5)  := 'XXWIP' ;            -- �A�v���P�[�V����
  gc_err_code_no_data     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122' ;  -- �f�[�^�O�����b�Z�[�W
--
  ------------------------------
  -- �Q�ƃR�[�h
  ------------------------------
  -- �i�ڃJ�e�S����
  gc_cat_set_name_prod      CONSTANT VARCHAR2(10) := '���i�敪' ;
  -- ��\�^�C�v
  gc_order_type_s           CONSTANT VARCHAR2(1) := '1' ;   -- �o��
  gc_order_type_m           CONSTANT VARCHAR2(1) := '2' ;   -- �ړ�
  gc_order_type_p           CONSTANT VARCHAR2(1) := '3' ;   -- �x��
  gc_order_type_js          CONSTANT VARCHAR2(2) := '�o' ;
  gc_order_type_jm          CONSTANT VARCHAR2(2) := '��' ;
  gc_order_type_jp          CONSTANT VARCHAR2(2) := '�x' ;
  -- �d�ʗe�ϋ敪
  gc_wc_class_w             CONSTANT VARCHAR2(1) := '1' ;   -- �d��
  gc_wc_class_c             CONSTANT VARCHAR2(1) := '2' ;   -- �e��
  gc_wc_class_jw            CONSTANT VARCHAR2(2) := '�d' ;
  gc_wc_class_jc            CONSTANT VARCHAR2(2) := '�e' ;
  -- �_��O�敪
  gc_outside_contract_y     CONSTANT VARCHAR2(1) := '1' ;   -- �L
  gc_outside_contract_n     CONSTANT VARCHAR2(1) := '0' ;   -- ��
  gc_outside_contract_jy    CONSTANT VARCHAR2(2) := '�L' ;  -- �L
  gc_outside_contract_jn    CONSTANT VARCHAR2(2) := '��' ;  -- ��
  -- �x���m���
  gc_return_flag_y          CONSTANT VARCHAR2(1) := 'Y' ;
  gc_return_flag_n          CONSTANT VARCHAR2(1) := 'N' ;
  gc_return_flag_jy         CONSTANT VARCHAR2(2) := '�L' ;
  gc_return_flag_jn         CONSTANT VARCHAR2(2) := '��' ;
  -- �z����敪�R�[�h
  gc_code_division_s        CONSTANT VARCHAR2(1) := '1' ;
  gc_code_division_p        CONSTANT VARCHAR2(1) := '2' ;
  gc_code_division_m        CONSTANT VARCHAR2(1) := '3' ;
  -- �x�������敪
  gc_code_p_b_classe_p      CONSTANT VARCHAR2(1) := '1' ;   -- �x���^��
  gc_code_p_b_classe_b      CONSTANT VARCHAR2(1) := '2' ;   -- �����^��
--
  ------------------------------
  -- ���̑�
  ------------------------------
  -- �i�ڋ敪
  gc_item_div_gen         CONSTANT VARCHAR2(1)  := '1' ;  -- ����
  gc_item_div_shi         CONSTANT VARCHAR2(1)  := '2' ;  -- ����
  gc_item_div_han         CONSTANT VARCHAR2(1)  := '4' ;  -- �����i
  gc_item_div_sei         CONSTANT VARCHAR2(1)  := '5' ;  -- ���i
  gc_min_date_char        CONSTANT VARCHAR2(10) := '1900/01/01' ;
  gc_max_date_char        CONSTANT VARCHAR2(10) := '4712/12/31' ;
--
-- *----------* 2009/07/01 �{��#1551�Ή� start *----------*
    gc_carrier_code_min   CONSTANT VARCHAR2(4)  DEFAULT '0000' ;
    gc_carrier_code_max   CONSTANT VARCHAR2(4)  DEFAULT 'ZZZZ' ;
    gc_whs_code_min       CONSTANT VARCHAR2(4)  DEFAULT '0000' ;
    gc_whs_code_max       CONSTANT VARCHAR2(4)  DEFAULT 'ZZZZ' ;
    gc_delivery_no_min    CONSTANT VARCHAR2(12) DEFAULT '000000000000' ;
    gc_delivery_no_max    CONSTANT VARCHAR2(12) DEFAULT '999999999999' ;
    gc_request_no_min     CONSTANT VARCHAR2(12) DEFAULT '000000000000' ;
    gc_request_no_max     CONSTANT VARCHAR2(12) DEFAULT '999999999999' ;
-- *----------* 2009/07/01 �{��#1551�Ή� end   *----------*
--
  -- ===============================================================================================
  -- ���R�[�h�^�錾
  -- ===============================================================================================
  --------------------------------------------------
  -- ���̓p�����[�^�i�[�p
  --------------------------------------------------
  TYPE rec_param_data  IS RECORD
    (
      prod_div            VARCHAR2(1)         -- 01 : ���i�敪
     ,carrier_code_from   VARCHAR2(4)         -- 02 : �^���Ǝ�From
     ,carrier_code_to     VARCHAR2(4)         -- 03 : �^���Ǝ�To
     ,whs_code_from       VARCHAR2(4)         -- 04 : �o�Ɍ��q��From
     ,whs_code_to         VARCHAR2(4)         -- 05 : �o�Ɍ��q��To
     ,ship_date_from      DATE                -- 06 : �o�ɓ�From
     ,ship_date_to        DATE                -- 07 : �o�ɓ�To
     ,arrival_date_from   DATE                -- 08 : ����From
     ,arrival_date_to     DATE                -- 09 : ����To
     ,judge_date_from     DATE                -- 10 : ���ϓ�From
     ,judge_date_to       DATE                -- 11 : ���ϓ�To
     ,report_date_from    DATE                -- 12 : �񍐓�From
     ,report_date_to      DATE                -- 13 : �񍐓�To
     ,delivery_no_from    VARCHAR2(12)        -- 14 : �z��NoFrom
     ,delivery_no_to      VARCHAR2(12)        -- 15 : �z��NoTo
     ,request_no_from     VARCHAR2(12)        -- 16 : �˗�NoFrom
     ,request_no_to       VARCHAR2(12)        -- 17 : �˗�NoTo
     ,invoice_no_from     VARCHAR2(20)        -- 18 : �����NoFrom
     ,invoice_no_to       VARCHAR2(20)        -- 19 : �����NoTo
     ,order_type          VARCHAR2(1)         -- 20 : �󒍃^�C�v
     ,wc_class            VARCHAR2(1)         -- 21 : �d�ʗe�ϋ敪
     ,outside_contract    VARCHAR2(1)         -- 22 : �_��O
     ,return_flag         VARCHAR2(1)         -- 23 : �m���ύX
     ,output_flag         VARCHAR2(1)         -- 24 : ����
    ) ;
  gr_param              rec_param_data ;      -- �p�����[�^
--
  --------------------------------------------------
  -- �擾�f�[�^�i�[�p
  --------------------------------------------------
  TYPE rec_main_data  IS RECORD
    (
      prod_div          VARCHAR2(1)       -- ���i�敪
     ,prod_div_name     VARCHAR2(8)       -- ���i�敪����
     ,carrier_code      VARCHAR2(4)       -- �^���Ǝ҃R�[�h
     ,carrier_name      VARCHAR2(20)      -- �^���ƎҖ���
     ,judge_date        DATE              -- ���ϓ�
     ,judge_date_c      VARCHAR2(10)      -- ���ϓ��i�����j
     ,whs_code          VARCHAR2(4)       -- �q��
     ,ship_date         VARCHAR2(5)       -- ����
     ,arrival_date      VARCHAR2(5)       -- ����
     ,delivery_no       VARCHAR2(12)      -- �z��No
     ,request_no        VARCHAR2(12)      -- �˗�No
     ,invoice_no        VARCHAR2(20)      -- �����No
     ,code_division     VARCHAR2(1)       -- �z����R�[�h�敪
     ,ship_to_code      VARCHAR2(9)       -- �z����
     ,ship_to_name      VARCHAR2(30)      -- �z���於��
     ,distance_1        VARCHAR2(4)       -- �����P
     ,distance_2        VARCHAR2(4)       -- �����Q
-- S 2008/10/15 1.10 MOD BY Y.Yamamoto -------------------------------------------------------- S --
--     ,qty               VARCHAR2(4)       -- ����
     ,qty               VARCHAR2(9)       -- ����
-- E 2008/10/15 1.10 MOD BY Y.Yamamoto -------------------------------------------------------- E --
-- S 2008/07/24 1.6 MOD BY S.Takemoto---------------------------------------------------------- S --
--     ,weight            VARCHAR2(5)       -- �d��
     ,weight            VARCHAR2(6)       -- �d��
-- E 2008/07/24 1.6 MOD BY S.Takemoto---------------------------------------------------------- E --
     ,deliv_div         VARCHAR2(2)       -- �z���敪
     ,c_kei             NUMBER            -- �^���ƎҁF�_��^��
     ,c_kon             NUMBER            -- �^���ƎҁF���ڊ���
     ,c_pic             NUMBER            -- �^���ƎҁFPIC
     ,c_oth             NUMBER            -- �^���ƎҁF������
     ,c_sum             NUMBER            -- �^���ƎҁF�x�����v
     ,c_tsu             NUMBER            -- �^���ƎҁF�ʍs����
     ,i_kei             NUMBER            -- �ɓ����F�_��^��
     ,i_sei             NUMBER            -- �ɓ����F�����^��
     ,i_kon             NUMBER            -- �ɓ����F���ڊ���
     ,i_pic             NUMBER            -- �ɓ����FPIC
     ,i_oth             NUMBER            -- �ɓ����F������
     ,i_sum             NUMBER            -- �ɓ����F�x�����v
     ,i_tsu             NUMBER            -- �ɓ����F�ʍs����
     ,balance           NUMBER            -- ����
    ) ;
  TYPE tab_main_data IS TABLE OF rec_main_data INDEX BY BINARY_INTEGER ;
  gt_main_data  tab_main_data ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_xml_data_table     XML_DATA ;            -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx            NUMBER DEFAULT 0 ;    -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
--
  gn_user_id            fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID ;   -- ���O�C�����[�U�[�h�c
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
  /************************************************************************************************
   * Procedure Name   : prc_chk_param
   * Description      : �p�����[�^�`�F�b�N
   ************************************************************************************************/
  PROCEDURE prc_chk_param
    (
      ov_errbuf             OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_chk_param' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
-- *----------* 2009/07/01 �{��#1551�Ή� start *----------*
    lc_carrier_code_min   CONSTANT VARCHAR2(4)  := gc_carrier_code_min;
    lc_carrier_code_max   CONSTANT VARCHAR2(4)  := gc_carrier_code_max;
    lc_whs_code_min       CONSTANT VARCHAR2(4)  := gc_whs_code_min    ;
    lc_whs_code_max       CONSTANT VARCHAR2(4)  := gc_whs_code_max    ;
    lc_delivery_no_min    CONSTANT VARCHAR2(12) := gc_delivery_no_min ;
    lc_delivery_no_max    CONSTANT VARCHAR2(12) := gc_delivery_no_max ;
    lc_request_no_min     CONSTANT VARCHAR2(12) := gc_request_no_min  ;
    lc_request_no_max     CONSTANT VARCHAR2(12) := gc_request_no_max  ;
-- *----------* 2009/07/01 �{��#1551�Ή� end   *----------*
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_msg_code_01              CONSTANT VARCHAR2(50) := 'APP-XXWIP-10016' ;
    lc_msg_code_02              CONSTANT VARCHAR2(50) := 'APP-XXWIP-10028' ;
    lv_tok_name_1               CONSTANT VARCHAR2(50) := 'PARAM1' ;
    lv_tok_name_2               CONSTANT VARCHAR2(50) := 'PARAM2' ;
    lc_p_name_carrier_code_from CONSTANT VARCHAR2(50) := '�^���Ǝ�From' ;
    lc_p_name_carrier_code_to   CONSTANT VARCHAR2(50) := '�^���Ǝ�To' ;
    lc_p_name_whs_code_from     CONSTANT VARCHAR2(50) := '�o�Ɍ��q��From' ;
    lc_p_name_whs_code_to       CONSTANT VARCHAR2(50) := '�o�Ɍ��q��To' ;
    lc_p_name_ship_date_from    CONSTANT VARCHAR2(50) := '�o�ɓ�From' ;
    lc_p_name_ship_date_to      CONSTANT VARCHAR2(50) := '�o�ɓ�To' ;
    lc_p_name_arrival_date_from CONSTANT VARCHAR2(50) := '����From' ;
    lc_p_name_arrival_date_to   CONSTANT VARCHAR2(50) := '����To' ;
    lc_p_name_judge_date_from   CONSTANT VARCHAR2(50) := '���ϓ�From' ;
    lc_p_name_judge_date_to     CONSTANT VARCHAR2(50) := '���ϓ�To' ;
    lc_p_name_report_date_from  CONSTANT VARCHAR2(50) := '�񍐓�From' ;
    lc_p_name_report_date_to    CONSTANT VARCHAR2(50) := '�񍐓�To' ;
    lc_p_name_delivery_no_from  CONSTANT VARCHAR2(50) := '�z��NoFrom' ;
    lc_p_name_delivery_no_to    CONSTANT VARCHAR2(50) := '�z��NoTo' ;
    lc_p_name_request_no_from   CONSTANT VARCHAR2(50) := '�˗�NoFrom' ;
    lc_p_name_request_no_to     CONSTANT VARCHAR2(50) := '�˗�NoTo' ;
    lc_p_name_invoice_no_from   CONSTANT VARCHAR2(50) := '�����NoFrom' ;
    lc_p_name_invoice_no_to     CONSTANT VARCHAR2(50) := '�����NoTo' ;
--
-- *----------* 2009/07/01 �{��#1551�Ή� start *----------*
    -- �p�����[�^���ݒ莞�̃G���[
    lc_msg_code_03              CONSTANT VARCHAR2(50) := 'APP-XXWIP-10088' ;
-- *----------* 2009/07/01 �{��#1551�Ή� end   *----------*
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    lv_msg_code       VARCHAR2(100) ;
    lv_tok_val_1      VARCHAR2(100) ;
    lv_tok_val_2      VARCHAR2(100) ;
--
    -- ==================================================
    -- ��O�錾
    -- ==================================================
    ex_param_error    EXCEPTION ;
--
-- *----------* 2009/07/01 �{��#1551�Ή� start *----------*
    no_param_error    EXCEPTION ;
-- *----------* 2009/07/01 �{��#1551�Ή� end   *----------*
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
-- *----------* 2009/07/01 �{��#1551�Ή� start *----------*
    -- ====================================================
    -- �p�����[�^�w��`�F�b�N
    -- ====================================================
    -- �p�����[�^�w��Ȃ��̏ꍇ�A�G���[�Ƃ���
    -- �� �m���ύX�E���وȊO�̃p�����[�^
    --    main()�֐����Őݒ肵�Ă���l�Ɣ�r
    IF ((gr_param.prod_div           IS NULL )                   -- ���i�敪
    AND (gr_param.carrier_code_from  = lc_carrier_code_min )     -- �^���Ǝ�From
    AND (gr_param.carrier_code_to    = lc_carrier_code_max )     -- �^���Ǝ�To
    AND (gr_param.whs_code_from      = lc_whs_code_min)          -- �o�Ɍ��q��From
    AND (gr_param.whs_code_to        = lc_whs_code_max )         -- �o�Ɍ��q��To
    AND (gr_param.ship_date_from     = FND_DATE.CANONICAL_TO_DATE(gc_min_date_char)) -- �o�ɓ�From
    AND (gr_param.ship_date_to       = FND_DATE.CANONICAL_TO_DATE(gc_max_date_char)) -- �o�ɓ�To
    AND (gr_param.arrival_date_from  = FND_DATE.CANONICAL_TO_DATE(gc_min_date_char)) -- ����From
    AND (gr_param.arrival_date_to    = FND_DATE.CANONICAL_TO_DATE(gc_max_date_char)) -- ����To
    AND (gr_param.judge_date_from    = FND_DATE.CANONICAL_TO_DATE(gc_min_date_char)) -- ���ϓ�From
    AND (gr_param.judge_date_to      = FND_DATE.CANONICAL_TO_DATE(gc_max_date_char)) -- ���ϓ�To
    AND (gr_param.report_date_from   = FND_DATE.CANONICAL_TO_DATE(gc_min_date_char)) -- �񍐓�From
    AND (gr_param.report_date_to     = FND_DATE.CANONICAL_TO_DATE(gc_max_date_char)) -- �񍐓�To
    AND (gr_param.delivery_no_from   = lc_delivery_no_min )      -- �z��NoFrom
    AND (gr_param.delivery_no_to     = lc_delivery_no_max )      -- �z��NoTo
    AND (gr_param.request_no_from    = lc_request_no_min )       -- �˗�NoFrom
    AND (gr_param.request_no_to      = lc_request_no_max )       -- �˗�NoTo
    AND (gr_param.invoice_no_from    IS NULL )                   -- �����NoFrom
    AND (gr_param.invoice_no_to      IS NULL )                   -- �����NoTo
    AND (gr_param.order_type         IS NULL )                   -- �󒍃^�C�v
    AND (gr_param.wc_class           IS NULL )                   -- �d�ʗe�ϋ敪
    AND (gr_param.outside_contract   IS NULL )) THEN             -- �_��O
      lv_msg_code  := lc_msg_code_03 ;
      RAISE no_param_error ;
    END IF;
--
-- *----------* 2009/07/01 �{��#1551�Ή� end   *----------*
--
    -- ====================================================
    -- �t�]�`�F�b�N
    -- ====================================================
    -- ----------------------------------------------------
    -- �^���Ǝ�
    -- ----------------------------------------------------
    IF( gr_param.carrier_code_from > gr_param.carrier_code_to ) THEN
      lv_msg_code  := lc_msg_code_02 ;
      lv_tok_val_1 := lc_p_name_carrier_code_to ;
      lv_tok_val_2 := lc_p_name_carrier_code_from ;
      RAISE ex_param_error ;
    END IF ;
    -- ----------------------------------------------------
    -- �o�Ɍ��q��
    -- ----------------------------------------------------
    IF( gr_param.whs_code_from > gr_param.whs_code_to ) THEN
      lv_msg_code  := lc_msg_code_02 ;
      lv_tok_val_1 := lc_p_name_whs_code_to ;
      lv_tok_val_2 := lc_p_name_whs_code_from ;
      RAISE ex_param_error ;
    END IF ;
    -- ----------------------------------------------------
    -- �o�ɓ�
    -- ----------------------------------------------------
    IF( gr_param.ship_date_from > gr_param.ship_date_to ) THEN
      lv_msg_code  := lc_msg_code_01 ;
      lv_tok_val_1 := lc_p_name_ship_date_from ;
      lv_tok_val_2 := lc_p_name_ship_date_to ;
      RAISE ex_param_error ;
    END IF ;
    -- ----------------------------------------------------
    -- ����
    -- ----------------------------------------------------
    IF( gr_param.arrival_date_from > gr_param.arrival_date_to ) THEN
      lv_msg_code  := lc_msg_code_01 ;
      lv_tok_val_1 := lc_p_name_arrival_date_from ;
      lv_tok_val_2 := lc_p_name_arrival_date_to ;
      RAISE ex_param_error ;
    END IF ;
    -- ----------------------------------------------------
    -- ���ϓ�
    -- ----------------------------------------------------
    IF( gr_param.judge_date_from > gr_param.judge_date_to ) THEN
      lv_msg_code  := lc_msg_code_01 ;
      lv_tok_val_1 := lc_p_name_judge_date_from ;
      lv_tok_val_2 := lc_p_name_judge_date_to ;
      RAISE ex_param_error ;
    END IF ;
    -- ----------------------------------------------------
    -- �񍐓�
    -- ----------------------------------------------------
    IF( gr_param.report_date_from > gr_param.report_date_to ) THEN
      lv_msg_code  := lc_msg_code_01 ;
      lv_tok_val_1 := lc_p_name_report_date_from ;
      lv_tok_val_2 := lc_p_name_report_date_to ;
      RAISE ex_param_error ;
    END IF ;
    -- ----------------------------------------------------
    -- �z��No
    -- ----------------------------------------------------
    IF( gr_param.delivery_no_from > gr_param.delivery_no_to ) THEN
      lv_msg_code  := lc_msg_code_02 ;
      lv_tok_val_1 := lc_p_name_delivery_no_to ;
      lv_tok_val_2 := lc_p_name_delivery_no_from ;
      RAISE ex_param_error ;
    END IF ;
    -- ----------------------------------------------------
    -- �˗�No
    -- ----------------------------------------------------
    IF( gr_param.request_no_from > gr_param.request_no_to ) THEN
      lv_msg_code  := lc_msg_code_02 ;
      lv_tok_val_1 := lc_p_name_request_no_to ;
      lv_tok_val_2 := lc_p_name_request_no_from ;
      RAISE ex_param_error ;
    END IF ;
    -- ----------------------------------------------------
    -- �����No
    -- ----------------------------------------------------
    IF( gr_param.invoice_no_from > gr_param.invoice_no_to ) THEN
      lv_msg_code  := lc_msg_code_02 ;
      lv_tok_val_1 := lc_p_name_invoice_no_to ;
      lv_tok_val_2 := lc_p_name_invoice_no_from ;
      RAISE ex_param_error ;
    END IF ;
--
  EXCEPTION
    -- =============================================================================================
    -- �p�����[�^�G���[
    -- =============================================================================================
    WHEN ex_param_error THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_application_wip
                     ,iv_name           => lv_msg_code
                     ,iv_token_name1    => lv_tok_name_1
                     ,iv_token_name2    => lv_tok_name_2
                     ,iv_token_value1   => lv_tok_val_1
                     ,iv_token_value2   => lv_tok_val_2
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
-- *----------* 2009/07/01 �{��#1551�Ή� start *----------*
    -- =============================================================================================
    -- �p�����[�^���ݒ�G���[
    -- =============================================================================================
    WHEN no_param_error THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_application_wip
                     ,iv_name           => lv_msg_code
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
-- *----------* 2009/07/01 �{��#1551�Ή� end   *----------*
--
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_chk_param ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_user
   * Description      : ���[�U�[���^�O�o��
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_user
    (
      ov_errbuf             OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_user' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �J�n�^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �f�[�^�^�O
    -- ====================================================
    -- ���[�h�c
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gc_report_id ;
    -- ���s��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( SYSDATE, 'YYYY/MM/DD HH24:MI:SS' ) ;
    -- ���O�C�����[�U�[�F��������
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_dept( FND_GLOBAL.USER_ID ) ;
    -- ���O�C�����[�U�[�F���[�U�[��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_name( FND_GLOBAL.USER_ID ) ;
--
    -- ====================================================
    -- �I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_xml_data_user ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_sql
   * Description      : �f�[�^�擾�r�p�k����
   ************************************************************************************************/
  PROCEDURE prc_create_sql
    (
      ov_errbuf             OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_sql' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_request_no_min     CONSTANT VARCHAR2(12) DEFAULT '000000000000' ;
    lc_request_no_max     CONSTANT VARCHAR2(12) DEFAULT '999999999999' ;
--
    -- ==================================================
    -- �J�[�\���錾
    -- ==================================================
    CURSOR cu_main
    IS
      SELECT xcat.segment1                                  AS prod_div         -- ���i�敪
-- S 2008/07/24 1.6 MOD BY S.Takemoto---------------------------------------------------------- S --
--            ,xcat.description                               AS prod_div_name    -- ���i�敪����
            ,SUBSTRB(xcat.description,1,8)                  AS prod_div_name    -- ���i�敪����
-- E 2008/07/24 1.6 MOD BY S.Takemoto---------------------------------------------------------- E --
            ,xcar.party_number                              AS carrier_code     -- �^���Ǝ҃R�[�h
            ,xcar.party_short_name                          AS carrier_name     -- �^���ƎҖ���
            ,xd1.judgement_date                             AS judge_date       -- ���ϓ�
            ,TO_CHAR( xd1.judgement_date, 'YYYY/MM/DD' )    AS judge_date_c     -- ���ϓ��i�����j
            ,NVL( xdl.whs_code, xd1.whs_code )              AS whs_code         -- �q��
            ,NVL( TO_CHAR( xdl.ship_date, 'MM/DD' )
                 ,TO_CHAR( xd1.ship_date, 'MM/DD' ) )       AS ship_date        -- ����
            ,NVL( TO_CHAR( xdl.arrival_date, 'MM/DD' )
                 ,TO_CHAR( xd1.arrival_date, 'MM/DD' ) )    AS arrival_date     -- ����
            ,xd1.delivery_no                                AS delivery_no      -- �z��No
            ,xdl.request_no                                 AS request_no       -- �˗�No
            ,NVL( xdl.invoice_no, xd1.invoice_no )          AS invoice_no       -- �����No
            ,NVL( xdl.code_division, xd1.code_division )    AS code_division    -- �z����R�[�h�敪
            ,NVL( xdl.shipping_address_code
                 ,xd1.shipping_address_code )               AS ship_to_code     -- �z����
            ,NULL                                           AS ship_to_name     -- �z���於��
            ,NVL( xd1.distance          , 0 )               AS distance_1       -- �����P
            ,NVL( xdl.distance          , 0 )               AS distance_2       -- �����Q
            ,NVL( xdl.qty               , 0 )               AS qty              -- ����
            ,NVL( xdl.delivery_weight   , 0 )               AS weight           -- �d��
-- ##### 20080725 1.8 �ύX�v�������e�X�g��Q�Ή� START #####
--            ,xdl.dellivary_classe                           AS deliv_div        -- �z���敪
            ,NVL(xdl.dellivary_classe ,xd1.delivery_classe) AS deliv_div        -- �z���敪
-- ##### 20080725 1.8 �ύX�v�������e�X�g��Q�Ή� END   #####
-- ##### 20081024 Ver.1.11 ����#439�Ή� START #####
--           ,NVL( xd2.charged_amount    , 0 )               AS c_kei      -- �^���ƎҁF�_��^��
           ,NVL( xd2.contract_rate      , 0 )               AS c_kei      -- �^���ƎҁF�_��^��
-- ##### 20081024 Ver.1.11 ����#439�Ή� END   #####
            ,NVL( xd2.consolid_surcharge, 0 )               AS c_kon      -- �^���ƎҁF���ڊ���
            ,NVL( xd2.picking_charge    , 0 )               AS c_pic      -- �^���ƎҁFPIC
            ,NVL( xd2.many_rate         , 0 )               AS c_oth      -- �^���ƎҁF������
            ,NVL( xd2.total_amount      , 0 )               AS c_sum      -- �^���ƎҁF�x�����v
            ,NVL( xd2.congestion_charge , 0 )               AS c_tsu      -- �^���ƎҁF�ʍs����
            ,NVL( xd1.contract_rate     , 0 )               AS i_kei      -- �ɓ����F�_��^��
            ,NVL( xd1.charged_amount    , 0 )               AS i_sei      -- �ɓ����F�����^��
            ,NVL( xd1.consolid_surcharge, 0 )               AS i_kon      -- �ɓ����F���ڊ���
            ,NVL( xd1.picking_charge    , 0 )               AS i_pic      -- �ɓ����FPIC
            ,NVL( xd1.many_rate         , 0 )               AS i_oth      -- �ɓ����F������
            ,NVL( xd1.total_amount      , 0 )               AS i_sum      -- �ɓ����F�x�����v
            ,NVL( xd1.congestion_charge , 0 )               AS i_tsu      -- �ɓ����F�ʍs����
            ,NVL( xd1.balance           , 0 )               AS balance    -- ����
      FROM xxwip_deliverys        xd1   -- �^���w�b�_�[�A�h�I���i�����j
          ,xxwip_deliverys        xd2   -- �^���w�b�_�[�A�h�I���i�x���j
          ,xxwip_delivery_lines   xdl   -- �^�����׃A�h�I��
          ,xxcmn_carriers2_v      xcar  -- �^���Ǝҏ��View
          ,xxcmn_categories_v     xcat  -- �i�ڃJ�e�S�����View
      WHERE
      ----------------------------------------------------------------------------------------------
      -- �i�ڃJ�e�S�����View
      ----------------------------------------------------------------------------------------------
      -- ����
            xcat.category_set_name = gc_cat_set_name_prod
      -- ��������
      AND   xd1.goods_classe       = xcat.segment1
      ----------------------------------------------------------------------------------------------
      -- �^���Ǝҏ��View
      ----------------------------------------------------------------------------------------------
      -- ����
      AND   xd1.judgement_date         BETWEEN xcar.start_date_active
                                       AND     NVL( xcar.end_date_active, xd1.judgement_date )
      -- ��������
      AND   xd1.delivery_company_code  = xcar.party_number
      ----------------------------------------------------------------------------------------------
      -- �^�����׃A�h�I��
      ----------------------------------------------------------------------------------------------
      -- �p�����[�^����
-- S 2009/01/29 1.13 MOD BY M.Nomura ---------------------------------------------------------- S --
-- �˗�No�w��̏ꍇ�ɁA�˗�No�ɕR�t���z��No�ɂă`�F�b�N���X�g���o�͂���
--      AND   xdl.request_no(+)     BETWEEN gr_param.request_no_from    -- �˗�No
--                                  AND     gr_param.request_no_to      --
--      AND   (  gr_param.request_no_from = lc_request_no_min
--            OR xdl.request_no          IS NOT NULL          )
--      AND   (  gr_param.request_no_to   = lc_request_no_max
--            OR xdl.request_no          IS NOT NULL          )
      -- ��������
--      AND   xd1.delivery_no             = xdl.delivery_no(+)
      AND ( EXISTS ( SELECT  1
                     FROM  xxwip_delivery_lines   xdl_reqno    -- �^�����׃A�h�I��
                     WHERE xdl_reqno.request_no    BETWEEN gr_param.request_no_from    -- �˗�No From
                                                   AND     gr_param.request_no_to      --        To
                     AND   (  gr_param.request_no_from    = lc_request_no_min
                           OR xdl_reqno.request_no        IS NOT NULL         )
                     AND   (  gr_param.request_no_to      = lc_request_no_max
                           OR xdl_reqno.request_no        IS NOT NULL         )
                     AND   xdl_reqno.delivery_no          = xdl.delivery_no    )       -- �z��No
            -- �w��Ȃ��̏ꍇ�́A�`�[�Ȃ��z�Ԃ��o�͑ΏۂƂ���
            OR ( xdl.request_no IS NULL 
                AND gr_param.request_no_from = lc_request_no_min 
                AND gr_param.request_no_to   = lc_request_no_max ) )      -- �z��No
      AND   xd1.delivery_no             = xdl.delivery_no(+)
-- E 2009/01/29 1.13 MOD BY M.Nomura ---------------------------------------------------------- E --
      ----------------------------------------------------------------------------------------------
      -- �^���w�b�_�[�A�h�I���i�x���j
      ----------------------------------------------------------------------------------------------
      -- ����
      AND   xd2.p_b_classe  = gc_code_p_b_classe_p
      -- �p�����[�^����
-- S 2008/07/17 1.5 MOD BY S.Takemoto---------------------------------------------------------- S --
--      AND   xd2.return_flag = gr_param.return_flag -- �m���ύX
      AND  ( (xd2.return_flag            = gr_param.return_flag)             -- �m���ύX
          OR (gr_param.return_flag = gc_return_flag_n))     -- �p�����[�^.�m���ύX:N�̏ꍇ�͂��ׂ�
-- E 2008/07/17 1.5 MOD BY S.Takemoto---------------------------------------------------------- E --
      AND   xd2.output_flag = gr_param.output_flag -- ����
      -- ��������
      AND   xd1.delivery_no = xd2.delivery_no
      ----------------------------------------------------------------------------------------------
      -- �^���w�b�_�[�A�h�I���i�����j
      ----------------------------------------------------------------------------------------------
      -- ����
      AND   xd1.p_b_classe            = gc_code_p_b_classe_b
      -- �p�����[�^����
      AND   xd1.delivery_company_code BETWEEN gr_param.carrier_code_from  -- �^���Ǝ�
                                      AND     gr_param.carrier_code_to    --
      AND   xd1.whs_code              BETWEEN gr_param.whs_code_from      -- �o�Ɍ��q��
                                      AND     gr_param.whs_code_to        --
      AND   xd1.ship_date             BETWEEN gr_param.ship_date_from     -- �o�ɓ�
                                      AND     gr_param.ship_date_to       --
      AND   xd1.arrival_date          BETWEEN gr_param.arrival_date_from  -- ����
                                      AND     gr_param.arrival_date_to    --
      AND   xd1.judgement_date        BETWEEN gr_param.judge_date_from    -- ���ϓ�
                                      AND     gr_param.judge_date_to      --
-- S 2008/05/23 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--      AND   xd1.report_date           BETWEEN gr_param.report_date_from   -- �񍐓�
--                                      AND     gr_param.report_date_to     --
      AND   NVL( xd1.report_date, gr_param.report_date_from )
                                      BETWEEN gr_param.report_date_from   -- �񍐓�
                                      AND     gr_param.report_date_to     --
-- E 2008/05/23 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
      AND   xd1.delivery_no           BETWEEN gr_param.delivery_no_from   -- �z��No
                                      AND     gr_param.delivery_no_to     --
-- S 2008/05/23 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--      AND   xd1.invoice_no            BETWEEN gr_param.invoice_no_from    -- �����No
--                                      AND     gr_param.invoice_no_to      --
-- ##### 20080715 1.4 ST��Q�Ή�#444�i�L���Ή��j START #####
--      AND   NVL( xd1.invoice_no, gr_param.invoice_no_from )
--                                      BETWEEN gr_param.invoice_no_from    -- �����No
--                                      AND     gr_param.invoice_no_to      --
      AND   (
              -- �����No From To ��NULL�̏ꍇ
              (
                    (gr_param.invoice_no_from IS NULL)
                AND (gr_param.invoice_no_to   IS NULL)
              )
              OR
              -- �����No From To ������ NOT NULL �̏ꍇ
              (
                    (xd1.invoice_no             IS NOT NULL) 
                AND (gr_param.invoice_no_from   IS NOT NULL)
                AND (gr_param.invoice_no_to     IS NOT NULL)
                AND (xd1.invoice_no >= gr_param.invoice_no_from)
                AND (xd1.invoice_no <= gr_param.invoice_no_to)
              )
              OR
              -- �����No To ��NOT NULL�̏ꍇ
              (
                    (xd1.invoice_no             IS NOT NULL)
                AND (gr_param.invoice_no_from   IS NULL)
                AND (gr_param.invoice_no_to     IS NOT NULL)
                AND (xd1.invoice_no <= gr_param.invoice_no_to)
              )
              -- �����No From �� NOT NULL �̏ꍇ
              OR
              (
                    (xd1.invoice_no             IS NOT NULL) 
                AND (gr_param.invoice_no_from   IS NOT NULL)
                AND (gr_param.invoice_no_to     IS NULL)
                AND (xd1.invoice_no >= gr_param.invoice_no_from)
              )
            )
-- ##### 20080715 1.4 ST��Q�Ή�#444�i�L���Ή��j END   #####
-- E 2008/05/23 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
-- S 2008/05/23 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--      AND   (  gr_param.prod_div          IS NULL
--            OR xd1.goods_classe            = gr_param.prod_div )          -- ���i�敪
--      AND   (  gr_param.order_type        IS NULL
--            OR xd1.order_type              = gr_param.order_type )        -- �󒍃^�C�v
--      AND   (  gr_param.wc_class          IS NULL
--            OR xd1.weight_capacity_class   = gr_param.wc_class )          -- �d�ʗe�ϋ敪
--      AND   (  gr_param.outside_contract  IS NULL
--            OR xd1.outside_contract        = gr_param.outside_contract )  -- �_��O
      AND   xd1.goods_classe            = NVL( gr_param.prod_div        , xd1.goods_classe )
      AND   xd1.order_type              = NVL( gr_param.order_type      , xd1.order_type )
-- ##### 20080725 1.7 ST��Q�Ή�#456 START #####
--      AND   xd1.weight_capacity_class   = NVL( gr_param.wc_class        , xd1.weight_capacity_class  )
--      AND   xd1.outside_contract        = NVL( gr_param.outside_contract, xd1.outside_contract  )
      AND (
            ((gr_param.wc_class IS NOT NULL) AND (gr_param.wc_class = xd1.weight_capacity_class))
            OR
            ( gr_param.wc_class IS NULL)
          )
      AND (
            ((gr_param.outside_contract IS NOT NULL) AND (gr_param.outside_contract = xd1.outside_contract))
            OR
            ( gr_param.outside_contract IS NULL)
          )
-- ##### 20080725 1.7 ST��Q�Ή�#456 END   #####
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
      ORDER BY xcat.segment1
              ,xcar.party_number
              ,xd1.judgement_date
-- S 2008/10/15 1.10 MOD BY Y.Yamamoto -------------------------------------------------------- S --
              ,xd1.whs_code
              ,TO_NUMBER( xd1.delivery_no )
              ,NVL( xdl.whs_code, xd1.whs_code )
-- E 2008/10/15 1.10 MOD BY Y.Yamamoto -------------------------------------------------------- E --
              ,TO_NUMBER( xdl.request_no  )
    ;
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- ���C���f�[�^���o
    -- ====================================================
    OPEN  cu_main ;
    FETCH cu_main BULK COLLECT INTO gt_main_data ;
    CLOSE cu_main ;
--
    -- ====================================================
    -- �z���於�̎擾
    -- ====================================================
    <<loop_ship_to>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      BEGIN
        ------------------------------------------------------------
        -- �z����R�[�h�敪���u1�v�̏ꍇ
        ------------------------------------------------------------
        IF ( gt_main_data(i).code_division = gc_code_division_s ) THEN
-- S 2008/07/24 1.6 MOD BY S.Takemoto---------------------------------------------------------- S --
--          SELECT xil.description
--          INTO   gt_main_data(i).ship_to_name
--          FROM xxcmn_item_locations_v   xil   -- OPM�ۊǏꏊ���VIEW
--          WHERE xil.segment1 = gt_main_data(i).ship_to_code
--          ;
          SELECT SUBSTRB(xil.description ,1,30)
          INTO   gt_main_data(i).ship_to_name
          FROM xxcmn_item_locations2_v   xil   -- OPM�ۊǏꏊ���VIEW
          WHERE gt_main_data(i).judge_date
                  BETWEEN xil.date_from
                  AND     NVL( xil.date_to, gt_main_data(i).judge_date )
          AND xil.disable_date        IS NULL
          AND xil.segment1 = gt_main_data(i).ship_to_code
          ;
-- E 2008/07/24 1.6 MOD BY S.Takemoto---------------------------------------------------------- E --
        ------------------------------------------------------------
        -- �z����R�[�h�敪���u2�v�̏ꍇ
        ------------------------------------------------------------
        ELSIF ( gt_main_data(i).code_division = gc_code_division_p ) THEN
-- S 2008/07/24 1.6 MOD BY S.Takemoto---------------------------------------------------------- S --
--          SELECT xvs.vendor_site_name
--          INTO   gt_main_data(i).ship_to_name
--          FROM xxcmn_vendor_sites_v   xvs-- �d����T�C�g���VIEW2
-- mod start ver 1.9
--          SELECT SUBSTRB(xvs.vendor_site_name ,1,30)
          SELECT xvs.vendor_site_short_name
-- mod end ver 1.9
          INTO   gt_main_data(i).ship_to_name
          FROM xxcmn_vendor_sites2_v   xvs-- �d����T�C�g���VIEW2
-- E 2008/07/24 1.6 MOD BY S.Takemoto---------------------------------------------------------- E --
          WHERE gt_main_data(i).judge_date
                  BETWEEN xvs.start_date_active
                  AND     NVL( xvs.end_date_active, gt_main_data(i).judge_date )
          AND   xvs.vendor_site_code = gt_main_data(i).ship_to_code
-- ##### 20081215 Ver.1.12 �{��#40�Ή� START #####
          AND  xvs.inactive_date  IS NULL       -- ������
-- ##### 20081215 Ver.1.12 �{��#40�Ή� END   #####
          ;
        ------------------------------------------------------------
        -- �z����R�[�h�敪���u3�v�̏ꍇ
        ------------------------------------------------------------
        ELSIF ( gt_main_data(i).code_division = gc_code_division_m ) THEN
-- mod start ver 1.9
--          SELECT xps.party_site_short_name
          SELECT SUBSTRB(xps.party_site_full_name ,1,30)
-- mod end ver 1.9
          INTO   gt_main_data(i).ship_to_name
          FROM xxcmn_party_sites2_v   xps     -- �p�[�e�B�T�C�g���VIEW2
          WHERE gt_main_data(i).judge_date
                  BETWEEN xps.start_date_active
                  AND     NVL( xps.end_date_active, gt_main_data(i).judge_date )
          AND   xps.party_site_number = gt_main_data(i).ship_to_code
-- ##### 20081215 Ver.1.12 �{��#40�Ή� START #####
          AND xps.party_site_status     = 'A'         -- �p�[�e�B�T�C�g�}�X�^.�X�e�[�^�X
          AND xps.cust_acct_site_status = 'A'         -- �ڋq�T�C�g�}�X�^.�X�e�[�^�X
          AND xps.cust_site_uses_status = 'A'         -- �ڋq�g�p�ړI�}�X�^.�X�e�[�^�X
-- ##### 20081215 Ver.1.12 �{��#40�Ή� END   #####
          ;
        END IF ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gt_main_data(i).ship_to_name := NULL ;
-- ##### 20081215 Ver.1.12 �{��#40�Ή� START #####
        WHEN TOO_MANY_ROWS THEN   -- *** �f�[�^�擾�G���[ ***
          gt_main_data(i).ship_to_name := NULL ;
-- ##### 20081215 Ver.1.12 �{��#40�Ή� END   #####
      END ;
    END LOOP loop_ship_to ;
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF cu_main%ISOPEN THEN
        CLOSE cu_main ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF cu_main%ISOPEN THEN
        CLOSE cu_main ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF cu_main%ISOPEN THEN
        CLOSE cu_main ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_sql ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�ҏW
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_init                 CONSTANT  VARCHAR2(1) := '*' ;
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    ld_judge_date_min       DATE DEFAULT  FND_DATE.CANONICAL_TO_DATE( gc_max_date_char ) ;
    ld_judge_date_max       DATE DEFAULT  FND_DATE.CANONICAL_TO_DATE( gc_min_date_char ) ;
--
    -- �u���C�N���f�p�ϐ�
    lv_prod_div             VARCHAR2(1)   DEFAULT lc_init ;
    lv_carrier              VARCHAR2(4)   DEFAULT lc_init ;
    lv_judge_date           VARCHAR2(10)  DEFAULT lc_init ;
    lv_delivery_no          VARCHAR2(12)  DEFAULT lc_init ;
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- ���X�g�O���[�v�J�n�F�f�[�^���
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ====================================================
    -- ���X�g�O���[�v�J�n�F���i�敪
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_prod_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    <<main_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- ====================================================
      -- �u���C�N����F���i�敪
      -- ====================================================
      IF ( lv_prod_div <> gt_main_data(i).prod_div ) THEN
        -- --------------------------------------------------
        -- ���w�̏I���^�O�o��
        -- --------------------------------------------------
        -- ���񃌃R�[�h�ȊO�̏ꍇ
        IF ( lv_prod_div <> lc_init ) THEN
          -- ���׃��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �w�b�_�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �w�b�_���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ���f���O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_judge_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ���f�����X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_judge_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �^���Ǝ҃O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_carrier' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �^���Ǝ҃��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_carrier' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ���i�敪�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- ----------------------------------------------------
        -- �O���[�v�J�n�F���i�敪
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_prod_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �f�[�^�^�O�o��
        -- ----------------------------------------------------
        -- ���i�敪
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).prod_div ;
        -- ���i�敪����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).prod_div_name ;
--
        -- ----------------------------------------------------
        -- ���X�g�O���[�v�J�n�F�^���Ǝ�
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_carrier' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �u���C�N���f�p���ڂ̑ޔ�
        -- ----------------------------------------------------
        lv_prod_div    := gt_main_data(i).prod_div ;
        lv_carrier     := lc_init ;
        lv_judge_date  := lc_init ;
        lv_delivery_no := lc_init ;
--
      END IF ;
--
      -- ====================================================
      -- �u���C�N����F�^���Ǝ�
      -- ====================================================
      IF ( lv_carrier <> gt_main_data(i).carrier_code ) THEN
        -- --------------------------------------------------
        -- ���w�̏I���^�O�o��
        -- --------------------------------------------------
        -- ���񃌃R�[�h�ȊO�̏ꍇ
        IF ( lv_carrier <> lc_init ) THEN
          -- ���׃��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �w�b�_�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �w�b�_���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ���f���O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_judge_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ���f�����X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_judge_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �^���Ǝ҃O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_carrier' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- ----------------------------------------------------
        -- �O���[�v�J�n�F�^���Ǝ�
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_carrier' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �f�[�^�^�O�o��
        -- ----------------------------------------------------
        -- �^���Ǝ҃R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'carrier_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).carrier_code ;
        -- �^���ƎҖ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'carrier_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).carrier_name ;
--
        -- ----------------------------------------------------
        -- ���X�g�O���[�v�J�n�F���f��
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_judge_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �u���C�N���f�p���ڂ̑ޔ�
        -- ----------------------------------------------------
        lv_carrier     := gt_main_data(i).carrier_code ;
        lv_judge_date  := lc_init ;
        lv_delivery_no := lc_init ;
--
      END IF ;
--
      -- ====================================================
      -- �u���C�N����F���f��
      -- ====================================================
      IF ( lv_judge_date <> gt_main_data(i).judge_date_c ) THEN
        -- --------------------------------------------------
        -- ���w�̏I���^�O�o��
        -- --------------------------------------------------
        -- ���񃌃R�[�h�ȊO�̏ꍇ
        IF ( lv_judge_date <> lc_init ) THEN
          -- ���׃��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �w�b�_�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �w�b�_���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ���f���O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_judge_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- ----------------------------------------------------
        -- �O���[�v�J�n�F���f��
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_judge_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �f�[�^�^�O�o��
        -- ----------------------------------------------------
        -- ���f��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'judge_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).judge_date_c ;
--
        -- ----------------------------------------------------
        -- ���X�g�O���[�v�J�n�F�w�b�_
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_head' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �u���C�N���f�p���ڂ̑ޔ�
        -- ----------------------------------------------------
        lv_judge_date  := gt_main_data(i).judge_date_c ;
        lv_delivery_no := lc_init ;
--
        -- ----------------------------------------------------
        -- �ŏ��l�E�ő�l�̑ޔ�
        -- ----------------------------------------------------
        -- �ŏ��l
        IF ( ld_judge_date_min > gt_main_data(i).judge_date ) THEN
          ld_judge_date_min := gt_main_data(i).judge_date ;
        END IF ;
        -- �ő�l
        IF ( ld_judge_date_max < gt_main_data(i).judge_date ) THEN
          ld_judge_date_max := gt_main_data(i).judge_date ;
        END IF ;
--
      END IF ;
--
      -- ====================================================
      -- �u���C�N����F�w�b�_
      -- ====================================================
      IF ( lv_delivery_no <> gt_main_data(i).delivery_no ) THEN
        -- --------------------------------------------------
        -- ���w�̏I���^�O�o��
        -- --------------------------------------------------
        -- ���񃌃R�[�h�ȊO�̏ꍇ
        IF ( lv_delivery_no <> lc_init ) THEN
          -- ���׃��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �w�b�_�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- ----------------------------------------------------
        -- �O���[�v�J�n�F���f��
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_head' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �f�[�^�^�O�o��
        -- ----------------------------------------------------
        -- ����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).ship_date ;
        -- ����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arrival_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).arrival_date ;
        -- �z��No
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).delivery_no ;
        -- �����P
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'distance_1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).distance_1 ;
        -- �^���ƎҁF�_��^��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'c_kei' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).c_kei ;
        -- �^���ƎҁF���ڊ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'c_kon' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).c_kon ;
        -- �^���ƎҁFPIC
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'c_pic' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).c_pic ;
        -- �^���ƎҁF������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'c_oth' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).c_oth ;
        -- �^���ƎҁF�x�����v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'c_sum' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).c_sum ;
        -- �^���ƎҁF�ʍs����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'c_tsu' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).c_tsu ;
        -- �ɓ����F�_��^��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'i_kei' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).i_kei ;
        -- �ɓ����F�����^��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'i_sei' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).i_sei ;
        -- �ɓ����F���ڊ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'i_kon' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).i_kon ;
        -- �ɓ����FPIC
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'i_pic' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).i_pic ;
        -- �ɓ����F������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'i_oth' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).i_oth ;
        -- �ɓ����F�������v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'i_sum' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).i_sum ;
        -- �ɓ����F�ʍs����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'i_tsu' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).i_tsu ;
        -- ����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'balance' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).balance ;
--
        -- ----------------------------------------------------
        -- ���X�g�O���[�v�J�n�F����
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �u���C�N���f�p���ڂ̑ޔ�
        -- ----------------------------------------------------
        lv_delivery_no := gt_main_data(i).delivery_no ;
--
      END IF ;
--
      -- ====================================================
      -- ���׃O���[�v�o��
      -- ====================================================
      -- ----------------------------------------------------
      -- �O���[�v�J�n�F����
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- �o�ɑq��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'whs_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).whs_code ;
      -- �˗�No
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'request_no' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).request_no ;
      -- �����No
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'invoice_no' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).invoice_no ;
      -- �z����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_to_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).ship_to_code ;
      -- �z���於��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_to_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).ship_to_name ;
      -- �����Q
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'distance_2' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).distance_2 ;
      -- ����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'qty' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).qty ;
      -- �d��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'weight' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).weight ;
      -- �z���敪
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'deliv_div' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).deliv_div ;
--
      -- ----------------------------------------------------
      -- �O���[�v�I���F����
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_loop ;
--
    -- ====================================================
    -- �I���^�O�o��
    -- ====================================================
    -- ���׃��X�g�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �w�b�_�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �w�b�_���X�g�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ���f���O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_judge_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ���f�����X�g�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_judge_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �^���Ǝ҃O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_carrier' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �^���Ǝ҃��X�g�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_carrier' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ���i�敪�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ���i�敪���X�g�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- --------------------------------------------------
    -- ���f���o��
    -- --------------------------------------------------
    -- ���f��From
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'judge_date_min' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( ld_judge_date_min, 'YYYY/MM/DD' ) ;
    -- ���f��To
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'judge_date_max' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( ld_judge_date_max, 'YYYY/MM/DD' ) ;
--
    -- ====================================================
    -- ���X�g�O���[�v�I���F�f�[�^���
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �A�E�g�p�����[�^�Z�b�g
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode := lv_retcode ;    --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg  := lv_errmsg ;     --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_xml_data ;
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION convert_into_xml
    (
      iv_name              IN        VARCHAR2   --   �^�O�l�[��
     ,iv_value             IN        VARCHAR2   --   �^�O�f�[�^
     ,ic_type              IN        CHAR       --   �^�O�^�C�v
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'convert_into_xml' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF ( ic_type = 'D' ) THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END convert_into_xml ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_prod_div           IN     VARCHAR2         -- 01 : ���i�敪
     ,iv_carrier_code_from  IN     VARCHAR2         -- 02 : �^���Ǝ�From
     ,iv_carrier_code_to    IN     VARCHAR2         -- 03 : �^���Ǝ�To
     ,iv_whs_code_from      IN     VARCHAR2         -- 04 : �o�Ɍ��q��From
     ,iv_whs_code_to        IN     VARCHAR2         -- 05 : �o�Ɍ��q��To
     ,iv_ship_date_from     IN     VARCHAR2         -- 06 : �o�ɓ�From
     ,iv_ship_date_to       IN     VARCHAR2         -- 07 : �o�ɓ�To
     ,iv_arrival_date_from  IN     VARCHAR2         -- 08 : ����From
     ,iv_arrival_date_to    IN     VARCHAR2         -- 09 : ����To
     ,iv_judge_date_from    IN     VARCHAR2         -- 10 : ���ϓ�From
     ,iv_judge_date_to      IN     VARCHAR2         -- 11 : ���ϓ�To
     ,iv_report_date_from   IN     VARCHAR2         -- 12 : �񍐓�From
     ,iv_report_date_to     IN     VARCHAR2         -- 13 : �񍐓�To
     ,iv_delivery_no_from   IN     VARCHAR2         -- 14 : �z��NoFrom
     ,iv_delivery_no_to     IN     VARCHAR2         -- 15 : �z��NoTo
     ,iv_request_no_from    IN     VARCHAR2         -- 16 : �˗�NoFrom
     ,iv_request_no_to      IN     VARCHAR2         -- 17 : �˗�NoTo
     ,iv_invoice_no_from    IN     VARCHAR2         -- 18 : �����NoFrom
     ,iv_invoice_no_to      IN     VARCHAR2         -- 19 : �����NoTo
     ,iv_order_type         IN     VARCHAR2         -- 20 : �󒍃^�C�v
     ,iv_wc_class           IN     VARCHAR2         -- 21 : �d�ʗe�ϋ敪
     ,iv_outside_contract   IN     VARCHAR2         -- 22 : �_��O
     ,iv_return_flag        IN     VARCHAR2         -- 23 : �m���ύX
     ,iv_output_flag        IN     VARCHAR2         -- 24 : ����
     ,ov_errbuf            OUT     VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           OUT     VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg            OUT     VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;                      --   ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;                   --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    lv_xml_string           VARCHAR2(32000) ;
    lv_err_code             VARCHAR2(10) ;
    ln_retcode              NUMBER ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ��������
    -- =====================================================
    -- -----------------------------------------------------
    -- �p�����[�^�i�[
    -- -----------------------------------------------------
    gr_param.prod_div            := iv_prod_div ;           -- 01 : ���i�敪
    gr_param.carrier_code_from   := iv_carrier_code_from ;  -- 02 : �^���Ǝ�From
    gr_param.carrier_code_to     := iv_carrier_code_to ;    -- 03 : �^���Ǝ�To
    gr_param.whs_code_from       := iv_whs_code_from ;      -- 04 : �o�Ɍ��q��From
    gr_param.whs_code_to         := iv_whs_code_to ;        -- 05 : �o�Ɍ��q��To
    gr_param.ship_date_from      := FND_DATE.CANONICAL_TO_DATE( iv_ship_date_from    ) ;
    gr_param.ship_date_to        := FND_DATE.CANONICAL_TO_DATE( iv_ship_date_to      ) ;
    gr_param.arrival_date_from   := FND_DATE.CANONICAL_TO_DATE( iv_arrival_date_from ) ;
    gr_param.arrival_date_to     := FND_DATE.CANONICAL_TO_DATE( iv_arrival_date_to   ) ;
    gr_param.judge_date_from     := FND_DATE.CANONICAL_TO_DATE( iv_judge_date_from   ) ;
    gr_param.judge_date_to       := FND_DATE.CANONICAL_TO_DATE( iv_judge_date_to     ) ;
    gr_param.report_date_from    := FND_DATE.CANONICAL_TO_DATE( iv_report_date_from  ) ;
    gr_param.report_date_to      := FND_DATE.CANONICAL_TO_DATE( iv_report_date_to    ) ;
    gr_param.delivery_no_from    := iv_delivery_no_from ;   -- 14 : �z��NoFrom
    gr_param.delivery_no_to      := iv_delivery_no_to ;     -- 15 : �z��NoTo
    gr_param.request_no_from     := iv_request_no_from ;    -- 16 : �˗�NoFrom
    gr_param.request_no_to       := iv_request_no_to ;      -- 17 : �˗�NoTo
    gr_param.invoice_no_from     := iv_invoice_no_from ;    -- 18 : �����NoFrom
    gr_param.invoice_no_to       := iv_invoice_no_to ;      -- 19 : �����NoTo
    gr_param.order_type          := iv_order_type ;         -- 20 : �󒍃^�C�v
    gr_param.wc_class            := iv_wc_class ;           -- 21 : �d�ʗe�ϋ敪
    gr_param.outside_contract    := iv_outside_contract ;   -- 22 : �_��O
    gr_param.return_flag         := iv_return_flag ;        -- 23 : �m���ύX
    gr_param.output_flag         := iv_output_flag ;        -- 24 : ����
--
    -- =====================================================
    -- �p�����[�^�`�F�b�N
    -- =====================================================
    prc_chk_param
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;

    -- =====================================================
    -- ���C���f�[�^�擾
    -- =====================================================
    prc_create_sql
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    --------------------------------------------------------
    -- �f�[�^���Ȃ��ꍇ
    --------------------------------------------------------
    IF ( gt_main_data.COUNT = 0 ) THEN
      -- --------------------------------------------------
      -- �O�����b�Z�[�W�̎擾
      -- --------------------------------------------------
      ov_retcode := gv_status_warn ;
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,gc_err_code_no_data ) ;
--
      -- --------------------------------------------------
      -- ���b�Z�[�W�̐ݒ�
      -- --------------------------------------------------
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis"?>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_carrier>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_carrier>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_carrier>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_carrier>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    ELSE
      -- =====================================================
      -- ���O�C�����[�U�[���o��
      -- =====================================================
      prc_create_xml_data_user
        (
          ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- �w�l�k�t�@�C���f�[�^�ҏW
      -- =====================================================
      prc_create_xml_data
        (
          ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- ���[�o��
      -- =====================================================
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
      -- --------------------------------------------------
      -- �f�[�^���o��
      -- --------------------------------------------------
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- �ҏW�����f�[�^���^�O�ɕϊ�
        lv_xml_string := convert_into_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name  -- �^�O�l�[��
                           ,iv_value  => gt_xml_data_table(i).tag_value  -- �^�O�f�[�^
                           ,ic_type   => gt_xml_data_table(i).tag_type  -- �^�O�^�C�v
                          ) ;
        -- �w�l�k�^�O�o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_xml_string) ;
      END LOOP xml_data_table ;
--
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    END IF ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  �Œ蕔 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_prod_div           IN     VARCHAR2         -- 01 : ���i�敪
     ,iv_carrier_code_from  IN     VARCHAR2         -- 02 : �^���Ǝ�From
     ,iv_carrier_code_to    IN     VARCHAR2         -- 03 : �^���Ǝ�To
     ,iv_whs_code_from      IN     VARCHAR2         -- 04 : �o�Ɍ��q��From
     ,iv_whs_code_to        IN     VARCHAR2         -- 05 : �o�Ɍ��q��To
     ,iv_ship_date_from     IN     VARCHAR2         -- 06 : �o�ɓ�From
     ,iv_ship_date_to       IN     VARCHAR2         -- 07 : �o�ɓ�To
     ,iv_arrival_date_from  IN     VARCHAR2         -- 08 : ����From
     ,iv_arrival_date_to    IN     VARCHAR2         -- 09 : ����To
     ,iv_judge_date_from    IN     VARCHAR2         -- 10 : ���ϓ�From
     ,iv_judge_date_to      IN     VARCHAR2         -- 11 : ���ϓ�To
     ,iv_report_date_from   IN     VARCHAR2         -- 12 : �񍐓�From
     ,iv_report_date_to     IN     VARCHAR2         -- 13 : �񍐓�To
     ,iv_delivery_no_from   IN     VARCHAR2         -- 14 : �z��NoFrom
     ,iv_delivery_no_to     IN     VARCHAR2         -- 15 : �z��NoTo
     ,iv_request_no_from    IN     VARCHAR2         -- 16 : �˗�NoFrom
     ,iv_request_no_to      IN     VARCHAR2         -- 17 : �˗�NoTo
     ,iv_invoice_no_from    IN     VARCHAR2         -- 18 : �����NoFrom
     ,iv_invoice_no_to      IN     VARCHAR2         -- 19 : �����NoTo
     ,iv_order_type         IN     VARCHAR2         -- 20 : �󒍃^�C�v
     ,iv_wc_class           IN     VARCHAR2         -- 21 : �d�ʗe�ϋ敪
     ,iv_outside_contract   IN     VARCHAR2         -- 22 : �_��O
     ,iv_return_flag        IN     VARCHAR2         -- 23 : �m���ύX
     ,iv_output_flag        IN     VARCHAR2         -- 24 : ����
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'xxcmn820004c.main' ;  -- �v���O������
    -- ======================================================
    -- ���[�J���萔
    -- ======================================================
-- *----------* 2009/07/01 �{��#1551�Ή� start *----------*
-- �����̃��[�J���萔�̐ݒ���R�����g�A�E�g
-- �O���[�o���萔��������悤�ɏC��
-- lc_invoice_no_min��lc_invoice_no_max�͎g�p���Ă��Ȃ�
--
--    lc_carrier_code_min   CONSTANT VARCHAR2(4)  DEFAULT '0000' ;
-- ##### 20080715 1.3 ST��Q�Ή�#444 START #####
--    lc_carrier_code_max   CONSTANT VARCHAR2(4)  DEFAULT '9999' ;
--    lc_carrier_code_max   CONSTANT VARCHAR2(4)  DEFAULT 'ZZZZ' ;
-- ##### 20080715 1.3 ST��Q�Ή�#444 END   #####
--    lc_whs_code_min       CONSTANT VARCHAR2(4)  DEFAULT '0000' ;
-- ##### 20080715 1.3 ST��Q�Ή�#444 START #####
--    lc_whs_code_max       CONSTANT VARCHAR2(4)  DEFAULT '9999' ;
--    lc_whs_code_max       CONSTANT VARCHAR2(4)  DEFAULT 'ZZZZ' ;
-- ##### 20080715 1.3 ST��Q�Ή�#444 END   #####
--    lc_delivery_no_min    CONSTANT VARCHAR2(12) DEFAULT '000000000000' ;
--    lc_delivery_no_max    CONSTANT VARCHAR2(12) DEFAULT '999999999999' ;
--    lc_request_no_min     CONSTANT VARCHAR2(12) DEFAULT '000000000000' ;
--    lc_request_no_max     CONSTANT VARCHAR2(12) DEFAULT '999999999999' ;
--    lc_invoice_no_min     CONSTANT VARCHAR2(20) DEFAULT '00000000000000000000' ;
-- ##### 20080715 1.3 ST��Q�Ή�#444 START #####
--    lc_invoice_no_max     CONSTANT VARCHAR2(20) DEFAULT '99999999999999999999' ;
--    lc_invoice_no_max     CONSTANT VARCHAR2(20) DEFAULT 'ZZZZZZZZZZZZZZZZZZZZ' ;
-- ##### 20080715 1.3 ST��Q�Ή�#444 END   #####
--
    lc_carrier_code_min   CONSTANT VARCHAR2(4)  := gc_carrier_code_min;
    lc_carrier_code_max   CONSTANT VARCHAR2(4)  := gc_carrier_code_max;
    lc_whs_code_min       CONSTANT VARCHAR2(4)  := gc_whs_code_min    ;
    lc_whs_code_max       CONSTANT VARCHAR2(4)  := gc_whs_code_max    ;
    lc_delivery_no_min    CONSTANT VARCHAR2(12) := gc_delivery_no_min ;
    lc_delivery_no_max    CONSTANT VARCHAR2(12) := gc_delivery_no_max ;
    lc_request_no_min     CONSTANT VARCHAR2(12) := gc_request_no_min  ;
    lc_request_no_max     CONSTANT VARCHAR2(12) := gc_request_no_max  ;
--
-- *----------* 2009/07/01 �{��#1551�Ή� end   *----------*
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1) ;         --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000) ;      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain
      (
        iv_prod_div           => iv_prod_div           -- 01 : ���i�敪
       ,iv_carrier_code_from  => NVL( iv_carrier_code_from, lc_carrier_code_min )
       ,iv_carrier_code_to    => NVL( iv_carrier_code_to  , lc_carrier_code_max )
       ,iv_whs_code_from      => NVL( iv_whs_code_from    , lc_whs_code_min )
       ,iv_whs_code_to        => NVL( iv_whs_code_to      , lc_whs_code_max )
       ,iv_ship_date_from     => NVL( iv_ship_date_from   , gc_min_date_char )
       ,iv_ship_date_to       => NVL( iv_ship_date_to     , gc_max_date_char )
       ,iv_arrival_date_from  => NVL( iv_arrival_date_from, gc_min_date_char )
       ,iv_arrival_date_to    => NVL( iv_arrival_date_to  , gc_max_date_char )
       ,iv_judge_date_from    => NVL( iv_judge_date_from  , gc_min_date_char )
       ,iv_judge_date_to      => NVL( iv_judge_date_to    , gc_max_date_char )
       ,iv_report_date_from   => NVL( iv_report_date_from , gc_min_date_char )
       ,iv_report_date_to     => NVL( iv_report_date_to   , gc_max_date_char )
       ,iv_delivery_no_from   => NVL( iv_delivery_no_from , lc_delivery_no_min )
       ,iv_delivery_no_to     => NVL( iv_delivery_no_to   , lc_delivery_no_max )
       ,iv_request_no_from    => NVL( iv_request_no_from  , lc_request_no_min )
       ,iv_request_no_to      => NVL( iv_request_no_to    , lc_request_no_max )
-- ##### 20080715 1.4 ST��Q�Ή�#444�i�L���Ή��j START #####
--       ,iv_invoice_no_from    => NVL( iv_invoice_no_from  , lc_invoice_no_min )
--       ,iv_invoice_no_to      => NVL( iv_invoice_no_to    , lc_invoice_no_max )
       ,iv_invoice_no_from    => iv_invoice_no_from
       ,iv_invoice_no_to      => iv_invoice_no_to
-- ##### 20080715 1.4 ST��Q�Ή�#444�i�L���Ή��j END   #####
       ,iv_order_type         => iv_order_type         -- 20 : �󒍃^�C�v
       ,iv_wc_class           => iv_wc_class           -- 21 : �d�ʗe�ϋ敪
       ,iv_outside_contract   => iv_outside_contract   -- 22 : �_��O
       ,iv_return_flag        => iv_return_flag        -- 23 : �m���ύX
       ,iv_output_flag        => iv_output_flag        -- 24 : ����
       ,ov_errbuf             => lv_errbuf            -- �G���[�E���b�Z�[�W
       ,ov_retcode            => lv_retcode           -- ���^�[���E�R�[�h
       ,ov_errmsg             => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
--
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwip730005c ;
/
